window.App.BackendImages ?= {}

window.App.BackendImages.updateGallery = (ev) ->
  $select = $(ev.target)
  id = $select.val()
  type = $select.find('option:selected').data('type')
  $('#image-gallery-type').val(type)
  $('#image-gallery-id').val(id)

window.App.BackendImages.stateChange = (ev) ->
  $element = $(ev.target)
  ev.preventDefault()
  map = []
  $("table input:checked").each ->
    map.push $(@).val()
  if map.length
    $.ajax
      url: $element.attr('href')
      dataType: 'json'
      method: 'PUT'
      data: {image_ids: map}
    .done (result) ->
      location.reload()
  else
    displayAlert "Please select at least one Entry"


$(document).on 'change', "#select-image-gallery-id", App.BackendImages.updateGallery

$ ->
  if $('#backend-images').length
    $('#enable-images').click App.BackendImages.stateChange
    $('#disable-images').click App.BackendImages.stateChange
