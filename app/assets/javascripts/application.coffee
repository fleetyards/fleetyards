#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require select2
#= require lib/spin
#= require lib/ladda
#= require lib/jquery.noty
#= require bootstrap
#= require dynamic_fields_for
#= require i18n
#= require i18n/translations
#= require helper
#= require app
#= require_tree ./app
#
#= require turbolinks

$(document).on 'click', 'a.disabled', (evt) ->
  false

$(document).on 'show.bs.collapse', '.navbar-collapse', (ev) ->
  $('.navbar-collapse.in').not(@).collapse('hide')

$ ->

  $('body > .container').css('min-height', $('body').height() - 101)

