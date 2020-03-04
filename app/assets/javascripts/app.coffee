window.laddaButton ?= {}

window.App ?= {}

window.App.initSelect = () ->
  $('select:not(.selectized)').selectize()

window.App.unloadSelect = () ->
  $selectize = $('select.selectized')
  selectize = $selectize[0].selectize if $selectize
  selectize.destroy() if selectize

$(document).on 'click', 'a.disabled', (evt) ->
  false

$(document).on 'dynamicFieldsFor.add', () ->
  App.initSelect()

window.addEventListener 'load', ->
  $('[data-toggle=tooltip]').tooltip()

  if success = $('body').attr('data-success')
    displaySuccess success

  if info = $('body').attr('data-info')
    displayAlert info

  if error = $('body').attr('data-error')
    displayError error

  if warning = $('body').attr('data-warning')
    displayWarning warning

  App.initSelect()
