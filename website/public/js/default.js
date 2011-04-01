$(function(){
	// hilite current
	var pathMatch = window.location.toString().match(/\/\w+$/)
	pathMatch = pathMatch ? pathMatch[0] : '/'
	$('#header a').each(function(){
		if($(this).attr('href') === pathMatch)
		$(this).css({'color':'#fff'})
	})
	prettyPrint();
})
