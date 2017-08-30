window.laddaButton ?= {}

window.App ?= {}

$(document).on 'click', 'a.disabled', (evt) ->
  false

$(document).on 'turbolinks:load', ->
  $('select.js-selectize').selectize()

  if success = $('body').attr('data-success')
    displaySuccess success

  if info = $('body').attr('data-info')
    displayAlert info

  if error = $('body').attr('data-error')
    displayError error

  if warning = $('body').attr('data-warning')
    displayWarning warning

  $('[data-toggle=tooltip]').tooltip()
