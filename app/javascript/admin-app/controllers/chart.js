import { Controller } from '@hotwired/stimulus'
import Highcharts from 'highcharts'
import axios from 'axios'

export default class ChartController extends Controller {
  static values = {
    height: String,
    refresh: { default: false, type: Boolean },
    tooltip: String,
    type: String,
    url: String,
  }

  chart = null

  chartData = null

  refreshInterval = null

  connect() {
    console.info('ChartController connect')

    this.element.classList.add('chart')
    this.element.style.height = this.heightValue

    this.setup()

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
        this.reload()
      }, 30 * 1000)
    }
  }

  clearRefresh() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  async setup() {
    this.element.classList.add('loading')

    await this.loadData()

    this.element.classList.remove('loading')

    this.chart = Highcharts.chart(this.element, {
      chart: {
        height: this.heightValue,
        type: this.typeValue,
      },
      ...this.chartOptions(),
    })
  }

  async reload() {
    await this.loadData()

    this.setData()
  }

  setData() {
    const series = this.chart.series[0]

    if (this.typeValue === 'pie') {
      series.setData(this.chartData)
      return
    }

    series.setData(this.chartData.map((item) => [item.tooltip, item.count]))
    this.chart.xAxis[0].setCategories(this.chartData.map((item) => item.label))
  }

  async loadData() {
    const { data } = await axios.get(this.urlValue)

    this.chartData = data
  }

  chartOptions() {
    if (this.typeValue === 'pie') {
      return this.pieChartOptions()
    }

    return this.defaultChartOptions()
  }

  defaultChartOptions() {
    const tooltip = this.tooltipValue

    return {
      legend: false,
      series: [
        {
          data: this.chartData.map((item) => [item.tooltip, item.count]),
        },
      ],
      tooltip: {
        formatter() {
          return window.I18n.t(`labels.charts.${tooltip}`, {
            count: this.y,
            label: this.key,
          })
        },
      },
      xAxis: {
        categories: this.chartData.map((item) => item.label),
      },
      yAxis: {
        allowDecimals: false,
      },
    }
  }

  pieChartOptions() {
    const tooltip = this.tooltipValue

    return {
      series: [
        {
          data: this.chartData,
        },
      ],
      tooltip: {
        formatter() {
          return window.I18n.t(`labels.charts.${tooltip}`, {
            count: this.y,
            label: this.key,
            percentage: Math.round(this.percentage),
          })
        },
      },
    }
  }
}
