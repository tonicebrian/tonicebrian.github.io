$(window).load(function () {
    $('.basic').flexslider({
        animation: "slide"
    });
    $('.simple-caption').flexslider({
        animation: "slide"
    });
    $('.thumbnail-img-control').flexslider({
        animation: "slide",
        controlNav: "thumbnails"
    });
    $('.basic-carousel').flexslider({
        animation: "slide",
        animationLoop: false,
        itemWidth: 210,
        itemMargin: 5
    });
});