window.App.Dashboard ?= {}

window.App.Dashboard.checkQuickStats = ->
  $.ajax
    url: '/quick-stats'
    dataType: "JSON"
    success: (data) ->
      return unless data
      $('#online-count').text(data.online_count)
      $('#ships-count-year').text(data.ships_count_year)
      $('#ships-count-total').text(data.ships_count_total)
      $('#users-count-total').text(data.users_count_total)

window.App.Dashboard.initCharts = ->
  @initModelsByManufacturerChart()
  @initModelsByClassificationChart()
  @initRegistrationsPerMonth()
  @initVisitsPerMonth()
  @initVisitsPerDay()

window.App.Dashboard.initModelsByManufacturerChart = ->
  Highcharts.chart('models-by-manufacturer-chart', {
    chart: {
      type: 'pie',
      height: '456px'
    },
    tooltip: {
      formatter: ->
        I18n.t('labels.charts.ship_pie', {
          label: this.key,
          count: this.y,
          percentage: Math.round(this.percentage)
        })
      ,
    }
    series: [{
      data: @modelsByManufacturerData
    }]
  })

window.App.Dashboard.initModelsByClassificationChart = ->
  Highcharts.chart('models-by-classification-chart', {
    chart: {
      type: 'pie',
      height: '456px'
    },
    tooltip: {
      formatter: ->
        I18n.t('labels.charts.ship_pie', {
          label: this.key,
          count: this.y,
          percentage: Math.round(this.percentage)
        })
      ,
    }
    series: [{
      data: @modelsByClassificationData
    }]
  })

window.App.Dashboard.initRegistrationsPerMonth = ->
  Highcharts.chart('registrations-per-month-chart', {
    chart: {
      type: 'column',
      height: '344px'
    },
    xAxis: {
      categories: @registrationsPerMonthData.map (item) -> item.label
    },
    yAxis: {
      allowDecimals: false
    },
    tooltip: {
      formatter: ->
        I18n.t('labels.charts.user', {
          label: this.key,
          count: this.y,
        })
      ,
    }
    legend: false,
    series: [{
      data: @registrationsPerMonthData.map (item) -> [item.tooltip, item.count]
    }]
  })

window.App.Dashboard.initVisitsPerMonth = ->
  Highcharts.chart('visits-per-month-chart', {
    chart: {
      type: 'column',
      height: '344px'
    },
    xAxis: {
      categories: @visitsPerMonthData.map (item) -> item.label
    },
    yAxis: {
      allowDecimals: false
    },
    tooltip: {
      formatter: ->
        I18n.t('labels.charts.user', {
          label: this.key,
          count: this.y,
        })
      ,
    }
    legend: false,
    series: [{
      data: @visitsPerMonthData.map (item) -> [item.tooltip, item.count]
    }]
  })

window.App.Dashboard.initVisitsPerDay = ->
  Highcharts.chart('visits-per-day-chart', {
    chart: {
      type: 'line',
      height: '344px'
    },
    xAxis: {
      categories: @visitsPerDayData.map (item) -> item.label
    },
    yAxis: {
      allowDecimals: false
    },
    tooltip: {
      formatter: ->
        I18n.t('labels.charts.user', {
          label: this.key,
          count: this.y,
        })
      ,
    }
    legend: false,
    series: [{
      data: @visitsPerDayData.map (item) -> [item.tooltip, item.count]
    }]
  })

document.addEventListener 'turbolinks:load', ->
  if $('#admin').length

    if App.Dashboard.quickStatsInterval
      clearInterval App.Dashboard.quickStatsInterval

    App.Dashboard.initCharts()

    App.Dashboard.quickStatsInterval = setInterval ->
      App.Dashboard.checkQuickStats()
      App.Dashboard.initVisitsPerDay()
    , 30 * 1000

