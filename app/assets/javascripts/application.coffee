#= require jquery
#= require jquery.turbolinks
#= require jquery_ujs
#= require select2
#= require bootstrap
#= require spin.js/spin
#= require ladda/js/ladda
#= require noty/js/noty/packaged/jquery.noty.packaged.min
#= require blueimp-gallery/js/jquery.blueimp-gallery.min
#= require blueimp-bootstrap-image-gallery/js/bootstrap-image-gallery.min
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
  $('#blueimp-gallery').data('useBootstrapModal', false)
  $('body > .container').css('min-height', $('body').height() - 175)

