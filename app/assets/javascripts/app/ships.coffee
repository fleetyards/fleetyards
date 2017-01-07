window.App.Ships ?= {}

window.App.Ships.workerPath = null

window.App.Ships.checkWorkerState = ->
  $.ajax
    url: App.Ships.workerPath
    dataType: "JSON"
    success: (data) ->
      return if data
      $('.reload-ships').removeClass('disabled')
      laddaButton.stop() if laddaButton
      clearInterval App.Ships.loadInterval
      displaySuccess I18n.t("messages.reload.success", resource: I18n.t("resources.ships"))

window.App.Ships.reload = ($element) ->
  laddaButton.start() if laddaButton
  $('.reload-ships').addClass('disabled')
  $.ajax
    url: $element.data('action')
    type: 'PUT'
    dataType: "JSON"
    success: ->
      App.Ships.workerPath = $element.data('workerpath')
      displayAlert I18n.t("messages.reload.startet", resource: I18n.t("resources.ships"))
      App.Ships.loadInterval = setInterval App.Ships.checkWorkerState, 3000

$(document).on 'ready page:load', ->
  if $('#backend, #ships').length
    button = document.querySelector('.ladda-button')
    if button
      window.laddaButton = Ladda.create(button)

    if $('.reload-ships.loading').length
      laddaButton.start() if laddaButton
      $('.reload-ships').removeClass('loading')
      App.Ships.workerPath = $('.reload-ships').data('workerpath')
      App.Ships.loadInterval = setInterval App.Ships.checkWorkerState, 3000
