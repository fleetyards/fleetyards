//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require select2
//= require sifter
//= require microplugin
//= require selectize
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
//= require nprogress
//= require unpoly
//= require unpoly-bootstrap3
//= require i18n
//= require i18n/translations
//= require helper
//= require tabs
//= require app
//= require_tree ./app
//
//= require turbolinks

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
  $('select.js-selectize').selectize();

  $('select.js-gallery-selectize').selectize({
    valueField: 'id',
    labelField: 'name',
    searchField: 'name',
    sortField: 'name',
    create: false,
    preload: true,
    maxOptions: 20,
    onChange: function(value) {
      $('#image-gallery-id').val(value);
    },
    load: function(query, callback) {
      $.ajax({
        url: 'https://api.fleetyards.net/v1/ships/',
        type: 'GET',
        datatype: 'json',
        error: function() {
          callback();
        },
        success: function(response) {
          callback(response);
        },
      });
    },
  });

  $('.btn.btn-primary[data-loading-text]').click(function() {
    $(this).button('loading');
  });

  $('#blueimp-gallery').data('useBootstrapModal', false);
});
