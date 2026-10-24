// Javascript file.
var openObjName;

function my_scroll( objName, speed, maxHeight ) {
	var mydiv = document.getElementById(objName);
	var cmd = "";

	// Get the current height.
	var oldHeight = mydiv.offsetHeight;
	
	// Speed is 0, so we need to start moving.
	if( speed == 0 ) {
		if( oldHeight > 1 ) {
			// Start Closing
			speed = -15;
		} else {
			// Start Opening
			speed = 10;
			if( openObjName && openObjName != objName ) {
				// Close the old tab
				var oldObj = document.getElementById(openObjName);
				cmd = "my_scroll('"+openObjName+"',-15,"+oldObj.offsetHeight+");";
				setTimeout( cmd, 50 );
			} // if close open obj.
			openObjName = objName;
			mydiv.style.display="block";
		} // else
	} // if speed.
	
	// Calculate the new height of the object
	var newHeight = oldHeight + speed;
	
	if( newHeight > maxHeight ) {
			mydiv.style.height = maxHeight;
	} else if( newHeight > 1 ) {
			mydiv.style.height = newHeight;
			cmd = "my_scroll('"+objName+"',"+speed+","+maxHeight+");";
			setTimeout( cmd, 50 );
	} else {
			mydiv.style.height = 1;
			mydiv.style.display="none";
	} // else
} // my_scroll()


function MM_preloadImages() { //v3.0
  var d=document; if(d.images){ if(!d.MM_p) d.MM_p=new Array();
    var i,j=d.MM_p.length,a=MM_preloadImages.arguments; for(i=0; i<a.length; i++)
    if (a[i].indexOf("#")!=0){ d.MM_p[j]=new Image; d.MM_p[j++].src=a[i];}}
} // MM_preloadImages()

function MM_swapImgRestore() { //v3.0
  var i,x,a=document.MM_sr; for(i=0;a&&i<a.length&&(x=a[i])&&x.oSrc;i++) x.src=x.oSrc;
} // MM_swapImgRestore()

function MM_findObj(n, d) { //v4.0
  var p,i,x;  if(!d) d=document; if((p=n.indexOf("?"))>0&&parent.frames.length) {
    d=parent.frames[n.substring(p+1)].document; n=n.substring(0,p);}
  if(!(x=d[n])&&d.all) x=d.all[n]; for (i=0;!x&&i<d.forms.length;i++) x=d.forms[i][n];
  for(i=0;!x&&d.layers&&i<d.layers.length;i++) x=MM_findObj(n,d.layers[i].document);
  if(!x && document.getElementById) x=document.getElementById(n); return x;
} // MM_findObj(n, d)

function MM_swapImage() { //v3.0
  var i,j=0,x,a=MM_swapImage.arguments; document.MM_sr=new Array; for(i=0;i<(a.length-2);i+=3)
   if ((x=MM_findObj(a[i]))!=null){document.MM_sr[j++]=x; if(!x.oSrc) x.oSrc=x.src; x.src=a[i+2];}
} // MM_swapImage()

function checkForm( form )
{
	var goodPubl = form.publisher.value.match(/\w/); 
	if( !goodPubl ) {
		alert( 'You must fill the publisher and ensure that it contains only letters, numbers and spaces.');
		form.publisher.focus();
		form.publisher.select();	
		return false;
	} // publisher
	
	var goodTitle = form.title.value.match(/\w/); 
	if( !goodTitle ) {
		alert( 'You must fill the game title and ensure that it contains only letters, numbers and spaces.');
		form.title.focus();
		form.title.select();	
		return false;
	} // title
	
	var goodSaveName = form.savename.value.match(/\w/); 
	if( !goodSaveName ) {
		alert( 'You must fill in a save name and ensure that it contains only letters, numbers and spaces.');
		form.savename.focus();
		form.savename.select();	
		return false;
	} // save name
	
	if( form.description.value.length == 0 ) {
		alert( 'Please enter a description for the game save');
		form.description.focus();
		form.description.select();
		return false;
	} // description
	
	if( form.binary.value.length == 0 ) {
		alert( 'Please select a game save to submit');
		return false;
	} // file
	
} // checkForm()

function showCopyright()
{
    Stamp=new Date();
    var Sal="th";
    var Month;
    var Year=Stamp.getYear();
    var Day=Stamp.getDate();
    var MonthVal=Stamp.getMonth() + 1;

    if(Year < 2000){Year += 1900;}
    
    switch(MonthVal) {
        case 12: Month="December";break;
        case 11: Month="November";break;
        case 10: Month="October";break;
        case  9: Month="September";break;
        case  8: Month="August";break;
        case  7: Month="July";break;
        case  6: Month="June";break;
        case  5: Month="May";break;
        case  4: Month="April";break;
        case  3: Month="March";break;
        case  2: Month="February";break;
        case  1: Month="January";break;
    } // switch
    
    switch(Day % 10) {
        case 1: Sal="st";break;
        case 2: Sal="nd";break;
        case 3: Sal="rd";break;
    } // switch
    
    document.write(
    '<font size="1" face="arial, helvetica" color="#333333">'
    +'&copy; '+Year+' '+'Fire International Ltd'
    +'<br/>'+Day+Sal+' '+Month+', '+Year+'</font>' );
    
} // showCopyright()


