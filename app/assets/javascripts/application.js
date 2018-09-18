//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require sifter
//= require microplugin
//= require bootstrap
//= require spin.js/spin
//= require ladda/js/ladda
//= require noty
//= require blueimp-gallery/js/jquery.blueimp-gallery.min
//= require blueimp-bootstrap-image-gallery/js/bootstrap-image-gallery.min
//= require blueimp-file-upload/js/vendor/jquery.ui.widget
//= require blueimp-tmpl/js/tmpl.min
//= require blueimp-load-image/js/load-image.min
//= require blueimp-file-upload/js/jquery.iframe-transport
//= require blueimp-file-upload/js/jquery.fileupload
//= require blueimp-file-upload/js/jquery.fileupload-ui
//= require blueimp-file-upload/js/jquery.fileupload-process
//= require blueimp-file-upload/js/jquery.fileupload-image
//= require blueimp-file-upload/js/jquery.fileupload-audio
//= require blueimp-file-upload/js/jquery.fileupload-video
//= require blueimp-file-upload/js/jquery.fileupload-validate
//= require dynamic_fields_for
//= require nprogress
//= require vendor/highcharts
//= require vendor/highcharts-theme
//= require chartkick
//= require i18n
//= require i18n/translations
//= require helper
//= require tabs
//= require app
//= require_tree ./app

Highcharts.setOptions({
  global: {
    allowDecimals: false,
  }
})

$(document).on('click', 'a.disabled', function() {
  return false;
});

$(document).on('show.bs.collapse', '.navbar-collapse', function() {
  $('.navbar-collapse.in').not(this).collapse('hide');
});

$(document).on('focus', '.modal input, .modal textarea, .modal select', function() {
  $(this)[0].scrollIntoView(true);
});

$(document).on('turbolinks:load', function() {
  $('.btn.btn-primary[data-loading-text]').click(function() {
    $(this).button('loading');
  });

  $('#blueimp-gallery').data('useBootstrapModal', false);
});
