$(document).bind 'dragover', (e) ->
  dropZone = $('#dropzone')
  timeout = window.dropZoneTimeout
  if !timeout
    dropZone.addClass('in')
  else
    clearTimeout(timeout)
  found = false
  node = e.target

  while (node isnt null)
    if node is dropZone[0]
      found = true
      break
    node = node.parentNode

  if found
    dropZone.addClass('hover');
  else
    dropZone.removeClass('hover')
  window.dropZoneTimeout = setTimeout ->
      window.dropZoneTimeout = null;
      dropZone.removeClass('in hover');
  , 100

$(document).bind 'drop dragover', (e) ->
    e.preventDefault()

document.addEventListener 'turbolinks:load', ->
  if $('#fileupload').length
    $('#fileupload').fileupload
      type: "POST"
      acceptFileTypes: /(\.|\/)(jpe?g|png)$/i
      prependFiles: true
      previewMaxWidth: 200
      previewMaxHeight: 100
      dropZone: $('#dropzone')

    $('#fileupload').addClass('fileupload-processing')

    if $('#fileupload').data('load-path') isnt undefined
      $.ajax
        url: $('#fileupload').data('load-path')
        dataType: 'json'
        context: $('#fileupload')[0]
      .always ->
        $(@).removeClass('fileupload-processing')
      .done (result) ->
        $(@).fileupload('option', 'done')
          .call(@, $.Event('done'), {result: result})
    else
      $('#fileupload').removeClass('fileupload-processing')
