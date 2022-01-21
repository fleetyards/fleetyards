import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['submenu', 'arrow']

  static values = {
    active: { type: Boolean, default: false },
  }

  submenuHeight = null

  visible = false

  connect() {
    console.info('SubmenuController connect')

    this.visible = this.activeValue

    this.calculateHeight()

    if (this.activeValue) {
      this.show()
    }

    this.submenuItems().forEach((element) => {
      element.addEventListener('focus', () => {
        this.show()
      })
    })
  }

  disconnect() {
    this.submenuItems().forEach((element) => {
      element.removeEventListener('focus', () => {
        this.show()
      })
    })
  }

  submenuItems() {
    return this.submenuTarget.querySelectorAll('a')
  }

  calculateHeight() {
    if (!this.activeValue) {
      this.submenuTarget.style.height = null
    }

    this.submenuHeight = this.submenuTarget.offsetHeight

    if (!this.activeValue) {
      this.submenuTarget.style.height = '0px'
    }
  }

  toggle(_event) {
    if (this.visible) {
      this.hide()
    } else {
      this.show()
    }
  }

  hide() {
    if (!this.visible) {
      return
    }

    this.submenuTarget.style.height = '0px'
    this.arrowTarget.classList.remove('rotate-90')

    this.visible = false
  }

  show() {
    if (this.visible) {
      return
    }

    this.submenuTarget.style.height = `${this.submenuHeight}px`
    this.arrowTarget.classList.add('rotate-90')

    this.visible = true
  }
}
