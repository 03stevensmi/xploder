#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Sync files that are missing from a remote branch, in batches of at most 1,000.

Usage:
  scripts/sync-uploaded-files.sh [--apply] [--source DIR] [--branch NAME]
                                 [--remote NAME] [--batch-size COUNT]

Paths are relative to the repository root. By default, the script scans the
whole repository and previews changes; pass --apply to commit and push them.
Each batch gets an automatic "Sync uploaded files (batch X of Y)" commit.
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

apply=false
source_arg=.
branch=
remote=origin
batch_size=1000

while (($#)); do
  case "$1" in
    --apply)
      apply=true
      shift
      ;;
    --source)
      (($# >= 2)) || die "--source requires a directory"
      source_arg=$2
      shift 2
      ;;
    --branch)
      (($# >= 2)) || die "--branch requires a branch name"
      branch=$2
      shift 2
      ;;
    --remote)
      (($# >= 2)) || die "--remote requires a remote name"
      remote=$2
      shift 2
      ;;
    --batch-size)
      (($# >= 2)) || die "--batch-size requires a number"
      batch_size=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1 (try --help)"
      ;;
  esac
done

[[ "$batch_size" =~ ^[1-9][0-9]*$ ]] || die "--batch-size must be a positive integer"
((batch_size <= 1000)) || die "--batch-size cannot exceed 1,000"

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel) ||
  die "Run this script from inside a Git repository"
script_path=$(realpath -- "${BASH_SOURCE[0]}")
script_rel=${script_path#"$repo_root"/}

if [[ "$source_arg" = /* ]]; then
  source_dir=$(cd -- "$source_arg" 2>/dev/null && pwd) ||
    die "Source directory does not exist: $source_arg"
else
  source_dir=$(cd -- "$repo_root/$source_arg" 2>/dev/null && pwd) ||
    die "Source directory does not exist: $source_arg"
fi
case "$source_dir/" in
  "$repo_root/"*) ;;
  *) die "Source directory must be inside the repository" ;;
esac

if [[ -z "$branch" ]]; then
  default_ref=$(git -C "$repo_root" symbolic-ref --quiet "refs/remotes/$remote/HEAD") ||
    die "Cannot determine the default branch for '$remote'; pass --branch"
  branch=${default_ref#refs/remotes/"$remote"/}
fi
git check-ref-format --branch "$branch" >/dev/null ||
  die "Invalid branch name: $branch"
git -C "$repo_root" remote get-url "$remote" >/dev/null 2>&1 ||
  die "Git remote not found: $remote"

current_branch=$(git -C "$repo_root" branch --show-current)
[[ "$current_branch" == "$branch" ]] ||
  die "Check out '$branch' before running this script (currently on '${current_branch:-detached HEAD}')"

git -C "$repo_root" diff --quiet ||
  die "Tracked working-tree changes exist; commit or stash them first"
git -C "$repo_root" diff --cached --quiet ||
  die "Staged changes exist; commit or unstage them first"

git -C "$repo_root" fetch "$remote" \
  "+refs/heads/$branch:refs/remotes/$remote/$branch" ||
  die "Could not fetch '$remote/$branch'"

counts=$(git -C "$repo_root" rev-list --left-right --count \
  "refs/remotes/$remote/$branch...HEAD")
read -r remote_only local_only <<<"$counts"
[[ "$remote_only" == 0 && "$local_only" == 0 ]] ||
  die "Local '$branch' must match '$remote/$branch'; synchronize it before continuing"

declare -A remote_paths=()
while IFS= read -r -d '' path; do
  remote_paths["$path"]=1
done < <(git -C "$repo_root" ls-tree -r -z --name-only "refs/remotes/$remote/$branch")

files=()
while IFS= read -r -d '' file; do
  relative_path=${file#"$repo_root"/}
  [[ "$relative_path" != "$script_rel" ]] || continue
  [[ -z "${remote_paths[$relative_path]+present}" ]] || continue
  if git -C "$repo_root" check-ignore -q -- "$relative_path"; then
    continue
  fi
  files+=("$relative_path")
done < <(find "$source_dir" -type d -name .git -prune -o \
  \( -type f -o -type l \) -print0)

if ((${#files[@]} == 0)); then
  printf "No untracked files are missing from '%s/%s'.\n" "$remote" "$branch"
  exit 0
fi

total=${#files[@]}
batch_count=$(((total + batch_size - 1) / batch_size))
printf "Found %d file(s) to sync in %d batch(es) to %s/%s.\n" \
  "$total" "$batch_count" "$remote" "$branch"
if [[ "$apply" != true ]]; then
  for file in "${files[@]}"; do
    printf '  %q\n' "$file"
  done
  printf 'Preview only. Re-run with --apply to commit and push these files.\n'
  exit 0
fi

for ((batch = 0; batch < batch_count; batch++)); do
  start=$((batch * batch_size))
  end=$((start + batch_size))
  ((end <= total)) || end=$total
  batch_files=("${files[@]:start:end-start}")
  batch_number=$((batch + 1))

  git -C "$repo_root" add -- "${batch_files[@]}" ||
    die "Could not stage batch $batch_number"
  git -C "$repo_root" commit -m "Sync uploaded files (batch $batch_number of $batch_count)" ||
    die "Could not commit batch $batch_number"
  git -C "$repo_root" push "$remote" "HEAD:refs/heads/$branch" ||
    die "Could not push batch $batch_number; the commit remains local"

  printf 'Synced batch %d/%d (%d file(s)).\n' \
    "$batch_number" "$batch_count" "${#batch_files[@]}"
done

printf 'All %d file(s) are synced to %s/%s.\n' "$total" "$remote" "$branch"
