window.App.Resources ?= {}

window.App.Resources.stateChange = ($element) ->
  $i = $element.find('i')
  data = {}
  data[$element.data('resource')] = {enabled: $i.hasClass('glyphicon-unchecked')}
  $.ajax
    url: $element.data('action')
    dataType: 'json'
    method: 'PUT'
    data: data
  .done (result) ->
    displaySuccess result.message
    $element.find('i').toggleClass('glyphicon-unchecked')
    $element.find('i').toggleClass('glyphicon-check')
