window.laddaButton ?= {}

window.App ?= {}

$(document).on 'click', 'a.disabled', (evt) ->
  false

document.addEventListener 'turbolinks:load', ->
  $('[data-toggle=tooltip]').tooltip()

  if success = $('body').attr('data-success')
    displaySuccess success

  if info = $('body').attr('data-info')
    displayAlert info

  if error = $('body').attr('data-error')
    displayError error

  if warning = $('body').attr('data-warning')
    displayWarning warning
