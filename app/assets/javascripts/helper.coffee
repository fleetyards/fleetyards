# Noty
window.displayNoty = (text, timeout, type) ->
  noty
    text: text,
    timeout: timeout,
    type: type,
    layout: 'bottomRight'

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

$ ->
  $("[data-notyConfirm]").click (ev) ->
    displayConfirm ev, $(@)
    return false
