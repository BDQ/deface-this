function deface(){
  $('#msg').hide();
  var original = escape($('#original').val());
  var original_format = $("[name='original_type']:checked").val();

  var selector = escape($('#selector').val());
  var closing_selector = escape($('#closing_selector').val());
  var action = $('#action').val();
  var source = escape($('#source').val());
  var replacement_format = $("[name='replacement_type']:checked").val();

  $.ajax({
    type: "POST",
    data: "original=" + original + "&original_format=" + original_format + "&selector=" + selector + "&closing_selector=" + closing_selector + "&action=" + action + "&source=" + source + "&replacement_format=" + replacement_format ,
    url: "/deface",
    success: function(res){
      if(res==""){
       $('#msg').show();
      }else{
        var result = JSON.parse(res);

        $('#escaped').html(result.escaped);

        if(result.count!=undefined){
          $('#match_count').html("Matches (" + result.count + ")");
        }

        if(result.closing_count!=undefined){
          $('#closing_match_count').html("Matches (" + result.closing_count + ")");
        }

        if(result.result!=undefined){
          $('#result').html(result.result);
        }
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
  $("#original, #selector, #closing_selector, #action, #source, [name='original_type'], [name='replacement_type']").change( function(){ deface() } );
  $('#original, #selector, #closing_selector, #action, #source').keyup( function(){
    delay(function(){
      deface();
    },500 );
  });

  $('#msg').ajaxError(function(e, xhr, settings, exception) {
    $(this).show();
    $('#match_count').html("Matches (ERROR)");
    $('#closing_match_count').html("Matches (ERROR)");
  });

});

