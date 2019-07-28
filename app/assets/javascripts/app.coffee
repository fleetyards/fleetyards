window.laddaButton ?= {}

window.App ?= {}

window.App.initSelect2 = () ->
  $(".select2").select2
    theme: "bootstrap"

$(document).on 'click', 'a.disabled', (evt) ->
  false

$(document).on 'dynamicFieldsFor.add', () ->
  App.initSelect2()

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

  App.initSelect2()
