window.App.Ships ?= {}

window.App.Ships.checkWorkerState = ->
  $.ajax
    url: r(backend_check_worker_state_path, "ShipsWorker")
    dataType: "JSON"
    success: (data) ->
      return if data
      $('.reload-ships').removeClass('disabled')
      laddaButton.stop() if laddaButton
      clearInterval App.Ships.loadInterval
      displaySuccess "Schiffe wurden erfolgreich aktualisiert."

window.App.Ships.reload = ($element) ->
  laddaButton.start() if laddaButton
  $('.reload-ships').addClass('disabled')
  $.ajax
    url: $element.attr('data-action')
    type: 'PUT'
    dataType: "JSON"
    success: ->
      displayAlert "Schiffe werden aktualisiert"
      App.Ships.loadInterval = setInterval App.Ships.checkWorkerState, 2000

$ ->
  if $('#backend, #ships').length
    button = document.querySelector('.ladda-button')
    if button
      window.laddaButton = Ladda.create(button)

    if $('.reload-ships.loading').length
      laddaButton.start() if laddaButton
      $('.reload-ships').removeClass('loading')
      App.Ships.loadInterval = setInterval App.Ships.checkWorkerState, 1000
