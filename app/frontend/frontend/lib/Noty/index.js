import Noty from 'noty'
import { isBefore, addSeconds } from 'date-fns'
import { I18n } from '@/frontend/lib/I18n'

Noty.overrideDefaults({
  callbacks: {
    onTemplate() {
      if (this.options.category === 'confirm') {
        this.barDom.innerHTML = `
          <div class="noty_body">${this.options.text}</div>
        `
        const buttons = []
        this.options.buttons.forEach((button) => {
          const inner = document.createElement('div')
          inner.setAttribute('class', 'panel-btn-inner')
          inner.textContent = button.dom.textContent
          button.dom.removeChild(button.dom.childNodes[0])
          button.dom.appendChild(inner)
          // @ts-ignore
          buttons.push(button.dom.outerHTML)
        })

        this.barDom.innerHTML += `
          <div class="noty_buttons">
            ${buttons.join('')}
          </div>
          <div class="noty_close_button override">
            <i class="fal fa-times"></i>
          </div>
          <div class="noty_progressbar"></div>
        `
      }

      if (this.options.category === 'notification') {
        this.barDom.innerHTML = `
          <div class="noty_body">${this.options.text}</div>
        `

        if (this.options.icon) {
          this.barDom.innerHTML += `
            <div class="noty_icon"><img src="${this.options.icon}" alt="icon" /></div>
          `
        }

        this.barDom.innerHTML += `
          <div class="noty_close_button override">
            <i class="fal fa-times"></i>
          </div>
          <div class="noty_progressbar"></div>
        `
      }
    },
  },
})

const notifyPermissionGranted = function notifyPermissionGranted() {
  return (
    'Notification' in window && window.Notification.permission === 'granted'
  )
}

const displayDesktopNotification = function displayDesktopNotification(
  message
) {
  const notification = new window.Notification(message, {
    // eslint-disable-next-line global-require
    icon: `${window.FRONTEND_ENDPOINT}${require('@/images/favicon.png')}`,
  })

  return notification
}

const displayNativeNotification = function displayNativeNotification(message) {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.ready.then(
      (registration) => {
        if (!registration.showNotification) {
          return
        }

        registration.showNotification(message, {
          icon: `${window.FRONTEND_ENDPOINT}/images/favicon.png`,
          vibrate: [200, 100, 200, 100, 200, 100, 200],
        })
      },
      () => {
        displayDesktopNotification(message)
      }
    )
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

const displayNotification = function displayNotification(options) {
  const defaults = {
    icon: null,
    notifyInBackground: true,
    text: null,
    timeout: 3000,
    type: 'info',
    ...options,
  }

  if (defaults.text && !notyBackoff(defaults.text)) {
    lastNotyAt = new Date()
    lastNotyText = defaults.text

    let displayText = defaults.text
    if (
      document.visibilityState !== 'visible' &&
      notifyPermissionGranted() &&
      defaults.notifyInBackground
    ) {
      notifyInBackground(displayText.replace(/(<([^>]+)>)/gi, ''))
    } else {
      if (Array.isArray(displayText)) {
        displayText = displayText.join('<br>')
      }
      new Noty({
        animation: {
          close: 'noty_effects_close',
          open: 'noty_effects_open',
        },

        category: 'notification',

        closeWith: ['click', 'button'],
        // @ts-ignore
        icon: defaults.icon,
        layout: 'topRight',
        progressBar: true,
        text: displayText,
        theme: 'metroui',
        timeout: defaults.timeout,
        type: defaults.type,
      }).show()
    }
  }
}

export const displayConfirm = function displayConfirm(options) {
  const defaults = {
    confirmBtnLayout: 'danger',
    layout: 'center',
    onCancel: () => {},
    onClose: () => {},
    onConfirm: () => {},
    text: null,
    ...options,
  }

  let btnClass = ''
  if (defaults.confirmBtnLayout !== 'default') {
    btnClass = ` btn-${defaults.confirmBtnLayout}`
  }

  const n = new Noty({
    animation: {
      close: 'noty_effects_close',
      open: 'noty_effects_open',
    },

    buttons: [
      Noty.button(
        I18n.t('actions.confirm'),
        `panel-btn panel-btn-inline${btnClass}`,
        () => {
          // @ts-ignore
          n.close()
          defaults.onConfirm()
        },
        { 'data-status': 'ok' }
      ),
      Noty.button(
        I18n.t('actions.cancel'),
        'panel-btn panel-btn-inline',
        () => {
          // @ts-ignore
          n.close()
          defaults.onCancel()
        }
      ),
    ],

    callbacks: {
      onClose() {
        defaults.onClose()
      },
    },

    // @ts-ignore
    category: 'confirm',

    closeWith: ['click', 'button'],

    id: 'noty-confirm',
    layout: defaults.layout,
    text: defaults.text,
    theme: 'metroui',
  }).show()
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

export const displayAlert = function alert(options) {
  displayNotification({
    ...options,
    notifyInBackground: false,
    timeout: 10000,
    type: 'error',
  })
}

export const displaySuccess = function success(options) {
  displayNotification({
    ...options,
    type: 'success',
  })
}

export const displayInfo = function info(options) {
  displayNotification({
    ...options,
    type: 'info',
  })
}

export const displayWarning = function warning(options) {
  displayNotification({
    ...options,
    type: 'warning',
  })
}
