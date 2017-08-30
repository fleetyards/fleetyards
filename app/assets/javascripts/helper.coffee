# Noty
window.displayNoty = (text, timeout, type) ->
  new Noty({
    text: text,
    type: type,
    timeout: timeout,
    layout: 'bottomRight',
    theme: 'metroui',
    closeWith: ['click', 'button'],
    animation: {
      open: 'noty_effects_open',
      close: 'noty_effects_close',
    },
    progressBar: true,
  }).show()

window.displayConfirm = (ev, $element) ->
  n = new Noty({
    text: $element.data('notyconfirm')
    buttons: [
      Noty.button(I18n.t('actions.ok'), 'btn btn-primary', ->
        n.close()
        if $element.find('form').length
          $element.find('form').submit()
        else
          window.location = $element.attr('href')
      , { 'data-status': 'ok' }
      ),
      Noty.button(I18n.t('actions.cancel'), 'btn btn-danger', ->
        n.close()
      )
    ]
    type: 'alert'
    layout: 'bottom'
    theme: 'metroui',
  }).show()

window.displaySuccess = (text, timeout = 2000) ->
  displayNoty text, timeout, 'success'

window.displayAlert = (text, timeout = 3000) ->
  displayNoty text, timeout, 'alert'

window.displayError = (text, timeout = false) ->
  displayNoty text, timeout, 'error'

window.displayWarning = (text, timeout = 3000) ->
  displayNoty text, timeout, 'warning'

$(document).on 'click', '[data-notyconfirm]', (ev) ->
  displayConfirm ev, $(@)
  false
