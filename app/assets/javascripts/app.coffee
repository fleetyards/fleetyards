window.laddaButton ?= {}

window.App ?= {}

$(document).on 'click', 'a.disabled', (evt) ->
  false

$(document).on 'turbolinks:load', ->
  if success = $('body').attr('data-success')
    displaySuccess success

  if info = $('body').attr('data-info')
    displayAlert info

  if error = $('body').attr('data-error')
    displayError error

  if warning = $('body').attr('data-warning')
    displayWarning warning

  $('.select2 select').select2
    formatNoMatches: (term) ->
      @element.attr('data-empty')

  $('[data-toggle=tooltip]').tooltip()
