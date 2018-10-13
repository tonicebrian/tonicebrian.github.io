/*-----------------------------------------------------------------------------------*/
/*	Accordion Active
/*-----------------------------------------------------------------------------------*/
$(document).ready(function () {
    $('.panel-collapse').on('show.bs.collapse', function () {
        $(this).siblings('.panel-heading').addClass('active-panel');
    });

    $('.panel-collapse').on('hide.bs.collapse', function () {
        $(this).siblings('.panel-heading').removeClass('active-panel');
    });
});