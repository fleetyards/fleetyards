import Noty from 'noty'
import { isBefore, addSeconds } from 'date-fns'
import { I18n } from 'frontend/lib/I18n'

const notifyPermissionGranted = function notifyPermissionGranted() {
  return ('Notification' in window) && window.Notification.permission === 'granted'
}

const displayDesktopNotification = function displayDesktopNotification(message) {
  const notification = new window.Notification(message, {
    // eslint-disable-next-line global-require
    icon: `${window.FRONTEND_ENDPOINT}${require('images/favicon.png')}`,
  })

  return notification
}

const displayNativeNotification = function displayNativeNotification(message) {
  if ('serviceWorker' in navigator) {
    // eslint-disable-next-line compat/compat
    navigator.serviceWorker.ready.then((registration) => {
      registration.showNotification(message, {
        icon: `${window.FRONTEND_ENDPOINT}/images/favicon.png`,
        vibrate: [200, 100, 200, 100, 200, 100, 200],
      })
    }, () => {
      displayDesktopNotification(message)
    })
  } else {
    displayDesktopNotification(message)
  }
}

const notifyInBackground = function notifyInBackground(text) {
  displayNativeNotification(text)
}

let lastNotyText = ''
let lastNotyAt = null

const notyBackoff = function notyBackoff(text) {
  if (lastNotyText !== text) {
    return false
  }
  const lastNoty = JSON.parse(JSON.stringify(lastNotyAt))
  if (isBefore(addSeconds(new Date(lastNoty), 2), new Date())) {
    return false
  }
  return true
}

const displayNotification = function displayNotification(overrides) {
  const options = {
    text: null,
    type: 'info',
    timeout: 3000,
    notifyInBackground: true,
    ...overrides,
  }

  if (options.text && !notyBackoff(options.text)) {
    lastNotyAt = new Date()
    lastNotyText = options.text

    let displayText = options.text
    if (document.visibilityState !== 'visible' && notifyPermissionGranted() && options.notifyInBackground) {
      notifyInBackground(displayText.replace(/(<([^>]+)>)/ig, ''))
    } else {
      if (Array.isArray(displayText)) {
        displayText = displayText.join('<br>')
      }
      new Noty({
        text: displayText,
        type: options.type,
        timeout: options.timeout,
        layout: 'topRight',
        theme: 'metroui',
        closeWith: ['click', 'button'],
        animation: {
          open: 'noty_effects_open',
          close: 'noty_effects_close',
        },
        progressBar: true,
      }).show()
    }
  }
}

export function requestPermission() {
  if (!('Notification' in window) || notifyPermissionGranted()) {
    return
  }

  window.Notification.requestPermission((permission) => {
    if (permission === 'granted') {
      displayNativeNotification(I18n.t('messages.notification.granted'))
    }
  })
}

export function confirm(text, confirmCallback, closeCallback = () => {}) {
  const n = new Noty({
    text,
    layout: 'center',
    theme: 'metroui',
    closeWith: ['click', 'button'],
    id: 'noty-confirm',
    modal: true,
    animation: {
      open: 'noty_effects_open',
      close: 'noty_effects_close',
    },
    buttons: [
      Noty.button(I18n.t('actions.confirm'), 'btn btn-danger', () => {
        n.close()
        confirmCallback()
      }, { 'data-status': 'ok' }),
      Noty.button(I18n.t('actions.cancel'), 'btn btn-default', () => {
        n.close()
      }),
    ],
    callbacks: {
      onClose() {
        closeCallback()
      },
    },
  }).show()
}

export function alert(text) {
  displayNotification({
    text,
    type: 'error',
    timeout: 10000,
    notifyInBackground: false,
  })
}

export function success(text) {
  displayNotification({
    text,
    type: 'success',
  })
}

export function info(text) {
  displayNotification({
    text,
    type: 'info',
  })
}

export default {
  alert, success, info, confirm,
}
