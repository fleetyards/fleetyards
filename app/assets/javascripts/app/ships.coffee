window.App.Ships ?= {}

window.App.Ships.workerPath = null

window.App.Ships.checkWorkerState = ->
  console.log App.Ships.workerPath
  $.ajax
    url: App.Ships.workerPath
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
    url: $element.data('action')
    type: 'PUT'
    dataType: "JSON"
    success: ->
      App.Ships.workerPath = $element.data('workerpath')
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
      App.Ships.workerPath = $('.reload-ships').data('workerpath')
      App.Ships.loadInterval = setInterval App.Ships.checkWorkerState, 1000
