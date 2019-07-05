$('.testimonials-slider').slick({
    autoplay: true,
    dots: false,
    infinite: true,
    arrows: false,
    speed: 300,
    slidesToShow: 1
});
$('.testimonials-2-testimonial').slick({
    slidesToShow: 1,
    slidesToScroll: 1,
    speed: 500,
    arrows: false,
    fade: false,
    asNavFor: '.testimonials-2-testimonial-nav',
    adaptiveHeight: true,
});
$('.testimonials-2-testimonial-nav').slick({
    slidesToShow: 3,
    slidesToScroll: 1,
    speed: 500,
    centerPadding: '0',
    asNavFor: '.testimonials-2-testimonial',
    dots: false,
    centerMode: true,
    focusOnSelect: true,
    infinite: true,
    responsive: [
        {
            breakpoint: 1199,
            settings: {
                slidesToShow: 3,
            }
        },
        {
            breakpoint: 991,
            settings: {
                slidesToShow: 3,
            }
        },
        {
            breakpoint: 767,
            settings: {
                slidesToShow: 3,
            }
        },
        {
            breakpoint: 480,
            settings: {
                slidesToShow: 3,
            }
        }
    ]
});