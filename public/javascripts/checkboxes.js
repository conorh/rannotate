function checkRanges(field, name) {
   var l = field.elements.length;
   var check = false;   
   
   for (i = 0; i < l; i++) 
   { 
   	 elm = field[i]
   	 if(elm.name == name && elm.type == "checkbox")
     {
     		if(elm.checked)
     			check = !check;
     		else if(check)
     			elm.checked = true;
     			
     		pct = parseInt(i/l*100);
     		if (pct % 5 == 0) window.status = 'Working (' + pct + '%)'; 
     } 

    window.status = 'Done';
  }
}	 
  
 function setCheckState(field, name, state) { 
   l = field.elements.length; 
      
   for (i = 0; i < l; i++) 
   {
   	elm = field[i];
   	
   	if(elm.name == name && elm.type == "checkbox")
   	{
     		pct = parseInt(i/l*100);
     		if (pct % 5 == 0) window.status = 'Working (' + pct + '%)';   
		  	elm.checked = state;
     } 
        
    	window.status = 'Done';
   	}    
 } 