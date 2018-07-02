window.App.Resources ?= {}

window.App.Resources.stateChange = ($element, attr) ->
  $i = $element.find('i')
  data = {}
  data[$element.data('resource')] = {"#{attr}": ($i.hasClass('fa-square') || $i.hasClass('fa-eye-slash'))}
  $.ajax
    url: $element.data('action')
    dataType: 'json'
    method: 'PUT'
    data: data
  .done (result) ->
    displaySuccess result.message
    if $i.hasClass('fa-square') || $i.hasClass('fa-check')
      $element.find('i').toggleClass('fa-square')
      $element.find('i').toggleClass('fa-check')
    if $i.hasClass('fa-eye-slash') || $i.hasClass('fa-eye')
      $element.find('i').toggleClass('fa-eye-slash')
      $element.find('i').toggleClass('fa-eye')
