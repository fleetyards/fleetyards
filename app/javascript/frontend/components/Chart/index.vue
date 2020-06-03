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
import HighchartSetup from 'frontend/mixins/HighchartSetup'

export default {
  mixins: [HighchartSetup],
  props: {
    type: {
      type: String,
      default: 'line',
    },
    loadData: {
      type: Function,
      required: true,
    },
    reload: {
      type: Number,
      default: null,
    },
    tooltipType: {
      type: String,
      default: '',
    },
    height: {
      type: Number,
      default: 400,
    },
  },
  data() {
    return {
      id: `chart-${this._uid.toString()}`,
      loading: false,
      instance: null,
      interval: null,
      data: [],
    }
  },
  computed: {
    chartWithCategory() {
      return ['bar', 'line', 'column', 'area'].includes(this.type)
    },
    xAxis() {
      if (this.chartWithCategory) {
        return {
          categories: this.data.map(item => item.label),
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
    legend() {
      if (this.chartWithCategory) {
        return false
      }
      return this.theme.legend
    },
    chartData() {
      if (this.chartWithCategory) {
        return this.data.map(item => [item.tooltip, item.count])
      }
      return this.data
    },
  },
  created() {
    this.setupHighchart()
    this.init()
  },
  mounted() {
    if (this.reload) {
      this.interval = setInterval(() => {
        this.reloadChart()
      }, this.reload * 1000)
    }
  },
  methods: {
    tooltipFormat(tooltip) {
      const options = {
        label: tooltip.key,
        count: tooltip.y,
      }

      if (this.type === 'pie') {
        options.percentage = Math.round(tooltip.percentage)
      }

      return this.$t(`labels.charts.${this.tooltipType}`, options)
    },
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
        series.setData(this.data.map(item => [item.tooltip, item.count]))
        this.instance.xAxis[0].setCategories(this.data.map(item => item.label))
      } else {
        series.setData(this.data)
      }
    },
    setupChart() {
      const self = this

      this.instance = chart(this.id, {
        chart: {
          type: this.type,
          height: this.height,
        },
        xAxis: this.xAxis,
        yAxis: this.yAxis,
        legend: this.legend,
        tooltip: {
          formatter() {
            return self.tooltipFormat(this)
          },
        },
        series: [
          {
            data: this.chartData,
          },
        ],
      })
    },
  },
}
</script>
