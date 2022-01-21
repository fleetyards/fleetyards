import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    console.info('BaseController connect')

    this.setupSelect()

    window.addEventListener('click', this.setupDisabled)
  }

  disconnect() {
    window.removeEventListener('click', this.setupDisabled)
  }

  setupDisabled(event) {
    const { target } = event

    if (
      target.classList.contains('disabled') ||
      target.getAttribute('disabled') === 'disabled'
    ) {
      event.stopPropagation()
      event.preventDefault()
    }
  }

  setupSelect() {
    // if $('select:not(.selectized)').length
    //   $('select:not(.selectized)').selectize()
  }
}
