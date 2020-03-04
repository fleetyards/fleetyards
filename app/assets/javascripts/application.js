//= require jquery
//= require jquery_ujs
//= require sifter
//= require microplugin
//= require bootstrap
//= require spin.js/spin
//= require ladda/js/ladda
//= require noty
//= require dynamic_fields_for
//= require nprogress
//= require selectize
//= require vendor/date_fns.min
//= require vendor/highcharts
//= require vendor/highcharts-theme
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
