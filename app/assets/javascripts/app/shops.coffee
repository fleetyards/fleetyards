window.App.Shops ?= {}

window.App.Shops.prefill = ($element) ->
  @loadData $element.data('apiurl'), (data) =>
    data.forEach (item) ->
      setTimeout ->
        $('.add_fields').click()
        $row = $('.fields:last')
        $row.find('select:first').val(item.gid.uri)
      , 200

window.App.Shops.loadData = (url, callback) ->
  $.ajax
    beforeSend: (request) ->
      request.setRequestHeader("Authorization", "Bearer #{window.JWT_TOKEN}")
    url: url
    dataType: "JSON"
    success: (data) ->
      callback(data)
