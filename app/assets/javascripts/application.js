//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require select2
//= require bootstrap
//= require spin.js/spin
//= require ladda/js/ladda
//= require noty/js/noty/packaged/jquery.noty.packaged.min
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
//= require cookies_eu
//= require i18n
//= require i18n/translations
//= require helper
//= require app
//= require_tree ./app
//
//= require turbolinks

$(document).on('click', 'a.disabled', function(evt) {
  return false;
});

$(document).on('show.bs.collapse', '.navbar-collapse', function(ev) {
  $('.navbar-collapse.in').not(this).collapse('hide');
});

$(function() {
  $('.btn.btn-primary[data-loading-text]').click(function() {
    $(this).button('loading');
  });

  $('#blueimp-gallery').data('useBootstrapModal', false);
});
