window.App.Resources ?= {}

window.App.Resources.stateChange = ($element) ->
  $i = $element.find('i')
  data = {}
  data[$element.data('resource')] = {enabled: $i.hasClass('fa-square-o')}
  $.ajax
    url: $element.data('action')
    dataType: 'json'
    method: 'PUT'
    data: data
  .done (result) ->
    displaySuccess result.message
    $element.find('i').toggleClass('fa-square-o')
    $element.find('i').toggleClass('fa-check')
