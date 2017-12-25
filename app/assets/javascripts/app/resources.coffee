window.App.Resources ?= {}

window.App.Resources.stateChange = ($element, attr) ->
  $i = $element.find('i')
  data = {}
  data[$element.data('resource')] = {"#{attr}": $i.hasClass('fa-square-o')}
  $.ajax
    url: $element.data('action')
    dataType: 'json'
    method: 'PUT'
    data: data
  .done (result) ->
    displaySuccess result.message
    $element.find('i').toggleClass('fa-square-o')
    $element.find('i').toggleClass('fa-check')
