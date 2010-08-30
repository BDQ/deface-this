function deface(){
  $('#msg').hide();
  var original = escape($('#original').val());
  var selector = escape($('#selector').val());
  var action = $('#action').val();
  var source = escape($('#source').val());

  $.ajax({
    type: "POST",
    data: "original=" + original + "&selector=" + selector + "&action=" + action + "&source=" + source,
    url: "/deface",
    success: function(res){
      var result = JSON.parse(res);

      $('#escaped').html(result.escaped);

      if(result.count!=undefined){
        $('#match_count').html("(" + result.count + ")");
      }

      if(result.result!=undefined){
        $('#result').html(result.result);
      }
    }
  });
}

var delay = (function(){
  var timer = 0;
  return function(callback, ms){
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})();

$(function() {
  $('#original, #selector, #action, #source').change( function(){ deface() } );
  $('#original, #selector, #action, #source').keyup( function(){
    delay(function(){
      deface();
    },500 );
  });

  $('#msg').ajaxError(function(e, xhr, settings, exception) {
      $(this).show();
  });

});

