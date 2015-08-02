<script type='text/javascript'>//<![CDATA[ 
$(function(){
	function moveScroll() {
		var scroll_top = $(window).scrollTop();
		var scroll_left = $(window).scrollLeft();
		var anchor_top = $("#main_table").offset().top;
		var anchor_left = $("#main_table").offset().left;
		var anchor_bottom = $("#bottom_anchor").offset().top;

		$("#clone").find("thead").css({
			width: $("#main_table thead").width()+"px",
			position: 'absolute',
			left: - scroll_left  + 'px'
		});

		$("#main_table").find(".first").css({
			position: 'absolute',
			left: scroll_left + anchor_left + 'px'
		});

		if (scroll_top >= anchor_top && scroll_top <= anchor_bottom) {
			clone_table = $("#clone");
			if (clone_table.length == 0) {
				clone_table = $("#main_table")
					.clone()
					.attr('id', 'clone')
					.css({
						width: $("#main_table").width()+"px",
						position: 'fixed',
						pointerEvents: 'none',
						left: $("#main_table").offset().left+'px',
						top: 0
					})
				.appendTo($("#table_container"))
					.css({
						visibility: 'hidden'
					})
				.find("thead").css({
					visibility: 'visible'
				});
			}
		}
		else {
			$("#clone").remove();
		}
	}

	$("#main_table")
		.wrap('<div id="table_container"></div>')
		.after('<div id="bottom_anchor"></div>');
	$(window).scroll(moveScroll);
});//]]>  

</script>
