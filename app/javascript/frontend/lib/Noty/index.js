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

const displayNotification = function displayNotification(overrides) {
  const options = {
    text: null,
    type: 'info',
    timeout: false,
    icon: null,
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
        icon: options.icon,
        timeout: options.timeout,
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
    Vue.prototype.$alert = function alert(text) {
      displayNotification({
        text,
        type: 'error',
        timeout: 10000,
        notifyInBackground: false,
      })
    }

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$success = function success(text, icon = null) {
      displayNotification({
        text,
        icon,
        type: 'success',
      })
    }

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$info = function info(text, icon = null) {
      displayNotification({
        text,
        icon,
        type: 'info',
      })
    }

    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$confirm = function confirm(overrides) {
      const options = {
        text: null,
        layout: 'center',
        confirmBtnLayout: 'danger',
        onConfirm: () => {},
        onClose: () => {},
        ...overrides,
      }

      const n = new Noty({
        text: options.text,
        layout: options.layout,
        theme: 'metroui',
        closeWith: ['click', 'button'],
        id: 'noty-confirm',
        category: 'confirm',
        animation: {
          open: 'noty_effects_open',
          close: 'noty_effects_close',
        },
        buttons: [
          Noty.button(I18n.t('actions.confirm'), `panel-btn panel-btn-inline btn-${options.confirmBtnLayout}`, () => {
            n.close()
            options.onConfirm()
          }, { 'data-status': 'ok' }),
          Noty.button(I18n.t('actions.cancel'), 'panel-btn panel-btn-inline', () => {
            n.close()
          }),
        ],
        callbacks: {
          onClose() {
            options.onClose()
          },
        },
      }).show()
    }
  },
}
