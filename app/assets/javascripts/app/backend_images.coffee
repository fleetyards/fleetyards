window.App.BackendImages ?= {}

window.App.BackendImages.updateGallery = (ev) ->
  $select = $(ev.target)
  id = $select.val()
  type = $select.find('option:selected').data('type')
  $('#image-gallery-type').val(type)
  $('#image-gallery-id').val(id)

$(document).on 'change', "#select-image-gallery-id", App.BackendImages.updateGallery
