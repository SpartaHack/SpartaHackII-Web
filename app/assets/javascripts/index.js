//jQuery("#title-text").fitText(1);
//jQuery(".responsive-text").fitText(1);

if (navigator.appVersion.indexOf("Win")!=-1) {
  $('#hero').find('a').addClass( "windowsCenter" );
}
$('#faq article h2').click(function() {
  $(this).next().slideToggle();
  $(this).children("i").toggleClass("fa-plus").toggleClass("fa-minus");
});

$('.anchorLink').click(function(){
  $('html, body').animate({
    scrollTop: $( $(this).attr('href') ).offset().top
  }, 500);
  return false;
});

// $("#header").headroom({
//   "offset": 205,
//   "tolerance": 5,
//   "classes": {
//     "initial": "animated",
//     "pinned": "slideDown",
//     "unpinned": "slideUp"
//   }
// });


var menu = [
  {"scroll_to": "#home-nav", "elem": $("#hero")},
  {"scroll_to": "#faq-nav", "elem": $("#faq")},
  {"scroll_to": "#contact-nav", "elem": $("#contact")},
];

var current = "home";

$(".svg-wrapper").hover( 
  function () { 
    $(".svg-wrapper").removeClass("active");
    $(this).addClass("active"); 
  },
  function () { 
    $(".svg-wrapper").removeClass("active");
    $(current).addClass("active"); 
  }

);

$(window).scroll(function() {
  var halfHeight = $(this).scrollTop() + ($(this).height() / 1.7);

  for(var i = 0; i < menu.length; i++) {
    var topOffset = menu[i]["elem"].offset().top;
    var height = menu[i]["elem"].height();

    if(halfHeight >= topOffset && halfHeight <= (topOffset + height) && current != menu[i]["scroll_to"]) {
      var scroll_to = menu[i]["scroll_to"];
      // change the selected menu element
      $(".svg-wrapper").removeClass("active");
      $(scroll_to).addClass("active");
      current = scroll_to;
    }
  }
});


