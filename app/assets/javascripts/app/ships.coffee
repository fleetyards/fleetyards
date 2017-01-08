window.App.Ships ?= {}

window.App.Ships.workerPath = null

window.App.Ships.checkWorkerState = (laddaButton, $element) ->
  $.ajax
    url: App.Ships.workerPath
    dataType: "JSON"
    success: (data) ->
      return if data
      $element.removeClass('disabled')
      laddaButton.stop()
      clearInterval App.Ships.loadInterval
      displaySuccess I18n.t("messages.reload.success", resource: I18n.t("resources.ships"))

window.App.Ships.reload = ($element) ->
  laddaButton = Ladda.create($element[0])
  laddaButton.start() if laddaButton
  $element.addClass('disabled')
  $.ajax
    url: $element.data('action')
    type: 'PUT'
    dataType: "JSON"
    success: ->
      App.Ships.workerPath = $element.data('workerpath')
      displayAlert I18n.t("messages.reload.startet", resource: I18n.t("resources.ships"))
      App.Ships.loadInterval = setInterval ->
        App.Ships.checkWorkerState(laddaButton, $element)
      , 3000

$(document).on 'ready page:load', ->
  if $('#backend, #ships').length
    if $('.reload-ships.loading').length
      $('.reload-ships.loading').each ($element) ->
        laddaButton = Ladda.create($element[0])
        laddaButton.start()
        $('.reload-ships').removeClass('loading')
        App.Ships.workerPath = $('.reload-ships').data('workerpath')
        App.Ships.loadInterval = setInterval ->
          App.Ships.checkWorkerState(laddaButton, $element)
        , 3000
