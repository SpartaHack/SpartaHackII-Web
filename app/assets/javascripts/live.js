console.log("Ha you're funny, looking under the hood")

var last_p = 1;

$('article').click(function() {
  current = $(this);
  $("article").removeClass("active-q");
  $(".a-hline").removeClass("hide");

  current.addClass("active-q");
  current.prev().addClass("hide");
  current.next().addClass("hide");

  $("#answers p:nth-child("+ last_p +")").fadeOut("fast", function() {
    $( "#answers p:nth-child("+ current.children().attr("id") +")" ).fadeIn();
  });

  last_p = current.children().attr("id")
});

$('#questions').on('scroll', function() {
    if($(this).scrollTop() + $(this).innerHeight() >= $(this)[0].scrollHeight) {
        $(".fa-angle-down").fadeOut();
    } else {
      $(".fa-angle-down").fadeIn();
    }

    if($(this).scrollTop() == 0) {
        $(".fa-angle-up").fadeOut();
    } else {
      $(".fa-angle-up").fadeIn();
    }
})

totalHeight = 0
$("#questions").children().each(function(){
    totalHeight = totalHeight + $(this).outerHeight(true);
});

if (totalHeight < $("#questions").height()) {
  $(".fa-angle-up").fadeOut();
  $(".fa-angle-down").fadeOut();
} else {
  $(".fa-angle-up").fadeOut();
}

$('#wrap-announce').on('scroll', function() {
    if ( $(this).scrollLeft() == 0) {
      $(".fa-chevron-left").fadeOut();
    } else if ($(this).scrollLeft() > ($(this).width() - $(this).width())) {
      $(".fa-chevron-left").fadeIn();
    }

    if ( $(this).scrollLeft() == $(this)[0].scrollWidth - $(this).width() ) {
      $(".fa-chevron-right").fadeOut();
    } else{
      $(".fa-chevron-right").fadeIn();
    }
})

$('.fa-chevron-left').click( function(){
  $('#wrap-announce').animate({scrollLeft: 0}, 800);
});

$('.fa-chevron-right').click( function(){
  $('#wrap-announce').animate({scrollLeft: $('#wrap-announce').scrollLeft() + 480}, 800);
});

$('.anchorLink').click(function(){
  $('html, body').animate({
    scrollTop: $( $(this).attr('href') ).offset().top - 58
  }, 500);
  return false;
});

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

if ($(window).width() < 960) {
  $("#header").headroom({
    "offset": 205,
    "tolerance": 5,
    "classes": {
      "initial": "animated",
      "pinned": "slideDown",
      "unpinned": "slideUp"
    }
  });
}

$(function() {
    var pull        = $('#pull');
        menu        = $('.mobile');

    $(pull).on('click', function(e) {
        e.preventDefault();
        menu.slideToggle();
    });

    $('.mobile li a').on('click', function(e) {
        menu.slideToggle();
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
