import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  connect() {
    console.info('DashboardController connect')
    // this.element.textContent = 'Hello World!'
  }
}
