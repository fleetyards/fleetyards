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

  # for bundledLocale of bundledLocales
  #   storedLocale = window.localStorage.getItem("res_#{bundledLocale}")?
  #   unless storedLocale?
  #     object = {}
  #     object[bundledLocale] = bundledLocales[bundledLocale]
  #     i18n.sync._storeLocal object

  locale = "en"

  i18n.init({
    # change default interpolation from __VARIABLE__ to rails-style %{VARIABLE}
    interpolationPrefix: '%{'
    interpolationSuffix: '}'
    fallbackLng: "en"

    # current locale to load
    lng: locale

    # rails-asset-localization path
    resGetPath: '/locales/%{lng}.json'

    # store locales for 1 day in localStorage
    useLocalStorage: true
    localStorageExpirationTime: 60 * 60 * 24 * 1000
  })

  $('#blueimp-gallery').data('useBootstrapModal', false)
  $('body > .container').css('min-height', $('body').height() - 245)
