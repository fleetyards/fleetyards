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

document.addEventListener 'turbolinks:load', ->
  if $('#admin').length

    if App.Dashboard.quickStatsInterval
      clearInterval App.Dashboard.quickStatsInterval

    App.Dashboard.quickStatsInterval = setInterval ->
      App.Dashboard.checkQuickStats()
    , 60 * 1000
