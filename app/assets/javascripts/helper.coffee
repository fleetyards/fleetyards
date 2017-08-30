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
  okButton =
    addClass: 'btn btn-primary'
    text: I18n.t('actions.ok')
    onClick: ($noty) ->
      $noty.close()
      if $element.find('form').length
        $element.find('form').submit()
      else
        window.location = $element.attr('href')
      return false

  cancelButton =
    addClass: 'btn btn-danger'
    text: I18n.t('actions.cancel')
    onClick: ($noty) ->
      $noty.close()
      return false

  noty
    text: $element.data('notyconfirm')
    buttons: [okButton, cancelButton]
    type: 'warning'
    layout: 'top'

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
