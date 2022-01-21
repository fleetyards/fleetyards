import { Controller } from '@hotwired/stimulus'
import axios from 'axios'

export default class extends Controller {
  static targets = [
    'onlineCount',
    'shipsCountYear',
    'shipsCountTotal',
    'usersCountTotal',
    'fleetsCountTotal',
  ]

  static values = {
    url: String,
  }

  refreshInterval = null

  connect() {
    console.info('QuickstatsController connect')

    this.loadData()

    this.setupRefresh()

    window.addEventListener('online', this.setupRefresh)
    window.addEventListener('offline', this.clearRefresh)
  }

  disconnect() {
    this.clearRefresh()

    window.removeEventListener('online', this.setupRefresh)
    window.removeEventListener('offline', this.clearRefresh)
  }

  setupRefresh() {
    if (this.refreshInterval) {
      this.refreshInterval = setInterval(() => {
        this.loadData()
      }, 30 * 1000)
    }
  }

  clearRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  async loadData() {
    const { data } = await axios.get(this.urlValue)

    this.onlineCountTarget.textContent = data.online_count
    this.shipsCountYearTarget.textContent = data.ships_count_year
    this.shipsCountTotalTarget.textContent = data.ships_count_total
    this.usersCountTotalTarget.textContent = data.users_count_total
    this.fleetsCountTotalTarget.textContent = data.fleets_count_total
  }
}
