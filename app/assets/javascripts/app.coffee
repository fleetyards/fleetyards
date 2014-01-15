window.Fleetyards ?= {}

$(document).on 'click', 'a.disabled', (evt) ->
  false

$ ->
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
