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

export default {
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
      theme: {
        colors: [
          '#428bca',
          '#90ee7e',
          '#f45b5b',
          '#7798BF',
          '#aaeeee',
          '#ff0066',
          '#eeaaee',
          '#55BF3B',
          '#DF5353',
          '#7798BF',
          '#aaeeee',
        ],
        chart: {
          backgroundColor: 'transparent',
          style: {
            fontSize: '11px',
          },
          plotBorderColor: '#606063',
        },
        title: {
          style: {
            color: '#E0E0E3',
            textTransform: 'uppercase',
            fontSize: '20px',
          },
          text: null,
        },
        subtitle: {
          style: {
            color: '#E0E0E3',
            textTransform: 'uppercase',
          },
        },
        xAxis: {
          gridLineColor: '#707073',
          labels: {
            style: {
              fontSize: '12px',
              color: '#E0E0E3',
            },
          },
          lineColor: '#707073',
          minorGridLineColor: '#505053',
          tickColor: '#707073',
          title: {
            text: null,
            style: {
              color: '#A0A0A3',
            },
          },
        },
        yAxis: {
          gridLineColor: '#707073',
          labels: {
            style: {
              fontSize: '12px',
              color: '#E0E0E3',
            },
          },
          lineColor: '#707073',
          minorGridLineColor: '#505053',
          tickColor: '#707073',
          tickWidth: 1,
          title: {
            text: null,
            style: {
              color: '#A0A0A3',
            },
          },
        },
        tooltip: {
          backgroundColor: 'rgba(0, 0, 0, 0.85)',
          style: {
            fontSize: '12px',
            color: '#F0F0F0',
          },
        },
        plotOptions: {
          area: {
            fillColor: 'rgba(66, 139, 202, 0.3)',
          },
          series: {
            dataLabels: {
              color: '#B0B0B3',
            },
            marker: {
              lineColor: '#333',
            },
          },
          boxplot: {
            fillColor: '#505053',
          },
          candlestick: {
            lineColor: 'white',
          },
          errorbar: {
            color: 'white',
          },
          column: {
            borderColor: '#333',
          },
          bar: {
            borderColor: '#333',
          },
          pie: {
            borderColor: '#333',
            innerSize: '50%',
            cursor: 'pointer',
            dataLabels: {
              enabled: false,
            },
            allowPointSelect: true,
            showInLegend: true,
          },
        },
        legend: {
          borderWidth: 0,
          itemMarginBottom: 3,
          itemStyle: {
            color: '#E0E0E3',
          },
          itemHoverStyle: {
            color: '#FFF',
          },
          itemHiddenStyle: {
            color: '#606063',
          },
        },
        credits: {
          enabled: false,
        },
        labels: {
          style: {
            color: '#707073',
          },
        },
        drilldown: {
          activeAxisLabelStyle: {
            color: '#F0F0F3',
          },
          activeDataLabelStyle: {
            color: '#F0F0F3',
          },
        },
        navigation: {
          buttonOptions: {
            symbolStroke: '#DDDDDD',
            theme: {
              fill: '#505053',
            },
          },
        },
        // scroll charts
        rangeSelector: {
          buttonTheme: {
            fill: '#505053',
            stroke: '#000000',
            style: {
              color: '#CCC',
            },
            states: {
              hover: {
                fill: '#707073',
                stroke: '#000000',
                style: {
                  color: 'white',
                },
              },
              select: {
                fill: '#000003',
                stroke: '#000000',
                style: {
                  color: 'white',
                },
              },
            },
          },
          inputBoxBorderColor: '#505053',
          inputStyle: {
            backgroundColor: '#333',
            color: 'silver',
          },
          labelStyle: {
            color: 'silver',
          },
        },

        navigator: {
          handles: {
            backgroundColor: '#666',
            borderColor: '#AAA',
          },
          outlineColor: '#CCC',
          maskFill: 'rgba(255,255,255,0.1)',
          series: {
            color: '#7798BF',
            lineColor: '#A6C7ED',
          },
          xAxis: {
            gridLineColor: '#505053',
          },
        },

        scrollbar: {
          barBackgroundColor: '#808083',
          barBorderColor: '#808083',
          buttonArrowColor: '#CCC',
          buttonBackgroundColor: '#606063',
          buttonBorderColor: '#606063',
          rifleColor: '#FFF',
          trackBackgroundColor: '#404043',
          trackBorderColor: '#404043',
        },

        // special colors for some of the
        legendBackgroundColor: 'rgba(0, 0, 0, 0.5)',
        background2: '#505053',
        dataLabelsColor: '#B0B0B3',
        textColor: '#C0C0C0',
        contrastTextColor: '#F0F0F3',
        maskColor: 'rgba(255,255,255,0.3)',
      },
    }
  },
  computed: {
    chartWithCategory() {
      return ['bar', 'line', 'column', 'area'].includes(this.type)
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
    legend() {
      if (this.chartWithCategory) {
        return false
      }
      return this.theme.legend
    },
    chartData() {
      if (this.chartWithCategory) {
        return this.data.map((item) => [item.tooltip, item.count])
      }
      return this.data
    },
  },
  created() {
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
          type: this.type,
          height: this.height,
        },
        xAxis: this.xAxis,
        yAxis: this.yAxis,
        legend: this.legend,
        tooltip: {
          ...this.theme.tooltip,
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
