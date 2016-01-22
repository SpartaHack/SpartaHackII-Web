console.log("Ha you're funny, looking under the hood")

if (navigator.appVersion.indexOf("Win")!=-1) {
  $('#hero').find('a').addClass( "windowsCenter" );
}
$('#faq article h3').click(function() {
  $(this).next().slideToggle();
});

$('.anchorLink').click(function(){
  $('html, body').animate({
    scrollTop: $( $(this).attr('href') ).offset().top - 58
  }, 500);
  return false;
});

var desktop_menu = [
  {"scroll_to": "#home-nav", "elem": $("#hero")},
  {"scroll_to": "#faq-nav", "elem": $("#faq")},
  {"scroll_to": "#contact-nav", "elem": $("#contact")},
  {"scroll_to": "#sponsor-nav", "elem": $("#sponsors")},
];

var current = "#home-nav";

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

if ($(window).width() < 775) {
  $("#header").headroom({
    "offset": 205,
    "tolerance": 5,
    "classes": {
      "initial": "animated",
      "pinned": "slideDown",
      "unpinned": "slideUp"
    }
  });
  $("#mlh-trust-badge").headroom({
    "offset": 205,
    "tolerance": 5,
    "classes": {
      "initial": "animated",
      "pinned": "slideDown-mlh",
      "unpinned": "slideUp-mlh"
    }
  });
}


$(window).scroll(function() {
  if ($(window).width() >= 775) {
    var halfHeight = $(this).scrollTop() + ($(this).height() / 1.7);

    for(var i = 0; i < desktop_menu.length; i++) {
      var topOffset = desktop_menu[i]["elem"].offset().top;
      var height = desktop_menu[i]["elem"].height();

      if(halfHeight >= topOffset && halfHeight <= (topOffset + height) && current != desktop_menu[i]["scroll_to"]) {
        var scroll_to = desktop_menu[i]["scroll_to"];
        // change the selected menu element
        $(".svg-wrapper").removeClass("active");
        $(scroll_to).addClass("active");
        current = scroll_to;
      }
    }

  }
});

mobile_toggle = 0;
function toggleMLH() {
  if (mobile_toggle == 0) {
    $('#mlh-trust-badge').animate({
      "marginTop": "+=220px"
    });
    mobile_toggle = 1
  } else {
    $('#mlh-trust-badge').animate({
      "marginTop": "-=220px"
    });
    mobile_toggle = 0
  }
}

$(function() {
    var pull        = $('#pull');
        menu        = $('.mobile');
 
    $(pull).on('click', function(e) {
        e.preventDefault();
        menu.slideToggle();
        toggleMLH()

    });

    $('.mobile li a').on('click', function(e) {
        menu.slideToggle();
         toggleMLH()

    });

});

function confirmJavascript() {
  $.ajax({
    url: "/javascript/confirm",
    context: document.body
  })
}

confirmJavascript();
setInterval(confirmJavascript, 10000); // invoke each 10 seconds



