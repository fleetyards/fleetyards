window.App ?= {}

$(document).on 'click', 'a.disabled', (evt) ->
  false

window.App.checkShipsWorkerState = ->
  $.ajax
    url: r(check_worker_state_path, "ShipsWorker")
    dataType: "JSON"
    success: (data) ->
      console.log data
      return if data
      $('.reload-ships').removeClass('disabled')
      laddaButton.stop() if laddaButton
      clearInterval App.loadInterval
      displaySuccess "Schiffe wurden erfolgreich aktualisiert."

window.App.reloadShips = ($element) ->
  laddaButton.start() if laddaButton
  $('.reload-ships').addClass('disabled')
  $.ajax
    url: $element.attr('data-action')
    type: 'PUT'
    dataType: "JSON"
    success: ->
      displayAlert "Schiffe werden aktualisiert"
      App.loadInterval = setInterval App.checkShipsWorkerState, 2000

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

  $('[data-toggle=tooltip]').tooltip()

  button = document.querySelector('.ladda-button')
  if button
    window.laddaButton = Ladda.create(button)

  if $('.reload-ships.loading').length
    laddaButton.start() if laddaButton
    $('.reload-ships').removeClass('loading')
    App.loadInterval = setInterval App.checkShipsWorkerState, 1000
