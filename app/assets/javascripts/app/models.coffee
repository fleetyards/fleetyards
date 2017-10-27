window.App.Models ?= {}

window.App.Models.workerPath = null

window.App.Models.checkWorkerState = (laddaButton, $element) ->
  $.ajax
    url: App.Models.workerPath
    dataType: "JSON"
    success: (data) ->
      return if data
      $element.removeClass('disabled')
      laddaButton.stop()
      clearInterval App.Models.loadInterval
      displaySuccess I18n.t("messages.reload.success", resource: I18n.t("resources.models"))

window.App.Models.reload = ($element) ->
  laddaButton = Ladda.create($element[0])
  laddaButton.start() if laddaButton
  $element.addClass('disabled')
  $.ajax
    url: $element.data('action')
    type: 'PUT'
    dataType: "JSON"
    success: ->
      App.Models.workerPath = $element.data('workerpath')
      displayAlert I18n.t("messages.reload.startet", resource: I18n.t("resources.models"))
      App.Models.loadInterval = setInterval ->
        App.Models.checkWorkerState(laddaButton, $element)
      , 3000


document.addEventListener 'turbolinks:load', ->
  if $('#admin, #models').length
    if $('.reload-models.loading').length
      $('.reload-models.loading').each ($element) ->
        laddaButton = Ladda.create($element[0])
        laddaButton.start()
        $('.reload-models').removeClass('loading')
        App.Models.workerPath = $('.reload-models').data('workerpath')
        App.Models.loadInterval = setInterval ->
          App.Models.checkWorkerState(laddaButton, $element)
        , 3000
