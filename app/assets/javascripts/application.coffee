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
#= require blueimp-file-upload/js/vendor/jquery.ui.widget
#= require blueimp-tmpl/js/tmpl.min
#= require blueimp-load-image/js/load-image.min
#= require blueimp-file-upload/js/jquery.iframe-transport
#= require blueimp-file-upload/js/jquery.fileupload
#= require blueimp-file-upload/js/jquery.fileupload-ui
#= require blueimp-file-upload/js/jquery.fileupload-process
#= require blueimp-file-upload/js/jquery.fileupload-image
#= require blueimp-file-upload/js/jquery.fileupload-audio
#= require blueimp-file-upload/js/jquery.fileupload-video
#= require blueimp-file-upload/js/jquery.fileupload-validate
#= require dynamic_fields_for
#= require i18next
#= require i18n/translations
#= require i18n_init
#= require helper
#= require app
#= require_tree ./app
#
#= require turbolinks

window.setMinHeight = ->
  offset = $('footer#main').outerHeight() + $('nav#main-nav').outerHeight() + 20
  $('body > .container').css('min-height', $('body').height() - offset)

$(document).on 'click', 'a.disabled', (evt) ->
  false

$(document).on 'show.bs.collapse', '.navbar-collapse', (ev) ->
  $('.navbar-collapse.in').not(@).collapse('hide')

$ ->
  $('#blueimp-gallery').data('useBootstrapModal', false)
  setMinHeight()
  $(window).resize ->
    setMinHeight()

