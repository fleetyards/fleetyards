<template>
  <div
    :id="id"
    :class="{
      loading,
    }"
    class="chart"
  />
</template>

<script>
import { chart } from 'highcharts'
import highchartsTheme from './highcharts-theme'

export default {
  name: 'ChartComponent',

  props: {
    height: {
      default: 400,
      type: Number,
    },
    loadData: {
      required: true,
      type: Function,
    },
    reload: {
      default: null,
      type: Number,
    },
    tooltipType: {
      default: '',
      type: String,
    },
    type: {
      default: 'line',
      type: String,
    },
  },

  data() {
    return {
      data: [],
      id: `chart-${this._uid.toString()}`,
      instance: null,
      interval: null,
      loading: false,
      theme: highchartsTheme,
    }
  },
  computed: {
    chartData() {
      if (this.chartWithCategory) {
        return this.data.map((item) => [item.tooltip, item.count])
      }
      return this.data
    },

    chartWithCategory() {
      return ['bar', 'line', 'column', 'area'].includes(this.type)
    },

    legend() {
      if (this.chartWithCategory) {
        return false
      }
      return this.theme.legend
    },

    xAxis() {
      if (this.chartWithCategory) {
        return {
          categories: this.data.map((item) => item.label),
        }
      }
      return {}
    },

    yAxis() {
      if (this.chartWithCategory) {
        return {
          allowDecimals: false,
        }
      }
      return {}
    },
  },

  mounted() {
    if (this.reload) {
      this.interval = setInterval(() => {
        this.reloadChart()
      }, this.reload * 1000)
    }
  },

  created() {
    this.init()
  },

  methods: {
    async init() {
      this.loading = true

      this.data = await this.loadData()

      this.loading = false

      this.setupChart()
    },

    async reloadChart() {
      this.data = await this.loadData()
      const series = this.instance.series[0]
      if (this.chartWithCategory) {
        series.setData(this.data.map((item) => [item.tooltip, item.count]))
        this.instance.xAxis[0].setCategories(
          this.data.map((item) => item.label)
        )
      } else {
        series.setData(this.data)
      }
    },

    setupChart() {
      const self = this

      this.instance = chart(this.id, {
        ...this.theme,
        chart: {
          ...this.theme.chart,
          height: this.height,
          type: this.type,
        },
        legend: this.legend,
        series: [
          {
            data: this.chartData,
          },
        ],
        tooltip: {
          ...this.theme.tooltip,
          formatter() {
            return self.tooltipFormat(this)
          },
        },
        xAxis: {
          ...this.theme.xAxis,
          ...this.xAxis,
        },
        yAxis: {
          ...this.theme.yAxis,
          ...this.yAxis,
        },
      })
    },

    tooltipFormat(tooltip) {
      const options = {
        count: tooltip.y,
        label: tooltip.key,
      }

      if (this.type === 'pie') {
        options.percentage = Math.round(tooltip.percentage)
      }

      return this.$t(`labels.charts.${this.tooltipType}`, options)
    },
  },
}
</script>
