import Noty from 'noty'
import { isBefore, addSeconds } from 'date-fns'
import { I18n } from 'frontend/lib/I18n'

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

const displayNotification = function displayNotification(options) {
  const defaults = {
    text: null,
    type: 'info',
    timeout: false,
    icon: null,
    notifyInBackground: true,
    ...options,
  }

  if (defaults.text && !notyBackoff(defaults.text)) {
    lastNotyAt = new Date()
    lastNotyText = defaults.text

    let displayText = defaults.text
    if (document.visibilityState !== 'visible' && notifyPermissionGranted() && defaults.notifyInBackground) {
      notifyInBackground(displayText.replace(/(<([^>]+)>)/ig, ''))
    } else {
      if (Array.isArray(displayText)) {
        displayText = displayText.join('<br>')
      }
      new Noty({
        text: displayText,
        type: defaults.type,
        icon: defaults.icon,
        timeout: defaults.timeout,
        category: 'notification',
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

const displayConfirm = function displayConfirm(options) {
  const defaults = {
    text: null,
    layout: 'center',
    confirmBtnLayout: 'danger',
    onConfirm: () => {},
    onClose: () => {},
    ...options,
  }

  const n = new Noty({
    text: defaults.text,
    layout: defaults.layout,
    theme: 'metroui',
    closeWith: ['click', 'button'],
    id: 'noty-confirm',
    category: 'confirm',
    animation: {
      open: 'noty_effects_open',
      close: 'noty_effects_close',
    },
    buttons: [
      Noty.button(I18n.t('actions.confirm'), `panel-btn panel-btn-inline btn-${defaults.confirmBtnLayout}`, () => {
        n.close()
        defaults.onConfirm()
      }, { 'data-status': 'ok' }),
      Noty.button(I18n.t('actions.cancel'), 'panel-btn panel-btn-inline', () => {
        n.close()
      }),
    ],
    callbacks: {
      onClose() {
        defaults.onClose()
      },
    },
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

export default {
  install(Vue) {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$alert = function alert(options) {
      displayNotification({
        ...options,
        type: 'error',
        timeout: 10000,
        notifyInBackground: false,
      })
    }

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$success = function success(options) {
      displayNotification({
        ...options,
        type: 'success',
      })
    }

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$info = function info(options) {
      displayNotification({
        ...options,
        type: 'info',
      })
    }

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$confirm = function confirm(options) {
      displayConfirm({
        ...options,
      })
    }
  },
}
