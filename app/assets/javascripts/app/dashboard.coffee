window.App.Dashboard ?= {}

window.App.Dashboard.checkQuickStats = (callback) ->
  $.ajax
    beforeSend: (request) ->
      request.setRequestHeader("Authorization", "Bearer #{window.JWT_TOKEN}")
    url: '/stats/quick-stats'
    dataType: "JSON"
    success: (data) ->
      return unless data
      $('#online-count').text(data.online_count)
      $('#ships-count-year').text(data.ships_count_year)
      $('#ships-count-total').text(data.ships_count_total)
      $('#users-count-total').text(data.users_count_total)

window.App.Dashboard.charts = []

window.App.Dashboard.addChart = (chart) ->
  @charts.push(chart)

window.App.Dashboard.findChart = (chartId) ->
  @charts.find((chart) -> chart.id is chartId)

window.App.Dashboard.loadChartData = (url, callback) ->
  $.ajax
    beforeSend: (request) ->
      request.setRequestHeader("Authorization", "Bearer #{window.JWT_TOKEN}")
    url: url
    dataType: "JSON"
    success: (data) ->
      callback(data)

window.App.Dashboard.reloadChart = (chartId) ->
  chart = @findChart(chartId)
  @loadChartData chart.url, (data) =>
    series = chart.instance.series[0]
    if chart.type in ['line', 'column']
      series.setData(data.map (item) -> [item.tooltip, item.count])
      chart.instance.xAxis[0].setCategories(data.map (item) -> item.label)
    else if chart.type is 'pie'
      series.setData(data)

window.App.Dashboard.setupChart = (chart) ->
  $("##{chart.id}").addClass('loading')
  @loadChartData chart.url, (data) =>
    $("##{chart.id}").removeClass('loading')
    switch chart.type
      when 'line' then @initLineChart(data, chart)
      when 'pie' then @initPieChart(data, chart)
      when 'column' then @initColumnChart(data, chart)
      else null

window.App.Dashboard.initCharts = ->
  @charts.forEach (chart) => @setupChart(chart)

window.App.Dashboard.initPieChart = (data, chart) ->
  chart.instance = Highcharts.chart(chart.id, {
    chart: {
      type: chart.type,
      height: chart.height,
    },
    tooltip: {
      formatter: ->
        I18n.t("labels.charts.#{chart.tooltip}", {
          label: this.key,
          count: this.y,
          percentage: Math.round(this.percentage)
        })
      ,
    }
    series: [{
      data: data
    }]
  })

window.App.Dashboard.initColumnChart = (data, chart) ->
  chart.instance = Highcharts.chart(chart.id, {
    chart: {
      type: chart.type,
      height: chart.height
    },
    xAxis: {
      categories: data.map (item) -> item.label
    },
    yAxis: {
      allowDecimals: false
    },
    tooltip: {
      formatter: ->
        I18n.t("labels.charts.#{chart.tooltip}", {
          label: this.key,
          count: this.y,
        })
      ,
    }
    legend: false,
    series: [{
      data: data.map (item) -> [item.tooltip, item.count]
    }]
  })

window.App.Dashboard.initLineChart = (data, chart) ->
  chart.instance = Highcharts.chart(chart.id, {
    chart: {
      type: chart.type,
      height: chart.height
    },
    xAxis: {
      categories: data.map (item) -> item.label
    },
    yAxis: {
      allowDecimals: false
    },
    tooltip: {
      formatter: ->
        I18n.t("labels.charts.#{chart.tooltip}", {
          label: this.key,
          count: this.y,
        })
      ,
    },
    legend: false,
    series: [{
      data: data.map (item) -> [item.tooltip, item.count]
    }]
  })

document.addEventListener 'turbolinks:load', ->
  if $('#admin').length

    if App.Dashboard.quickStatsInterval
      clearInterval App.Dashboard.quickStatsInterval

    App.Dashboard.initCharts()

    App.Dashboard.quickStatsInterval = setInterval ->
      App.Dashboard.checkQuickStats()
      App.Dashboard.reloadChart('visits-per-day-chart')
      App.Dashboard.reloadChart('visits-per-month-chart')
    , 60 * 1000

