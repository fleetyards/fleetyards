$(document).on('shown.bs.tab', 'a[data-toggle="tab"]', function(e) {
  if ($('form').length) {
    $('form input[name=hash]').val(e.target.hash);
    var formAction = $('form').attr('action').split("#")[0];
    $('form').attr('action', formAction + e.target.hash);
    history.pushState({}, "", e.target.hash);
  }
});

window.onpopstate = function() {
  Tabs.openByHash();
};

window.Tabs = {
  openByHash: function() {
    if ($('.nav-tabs a:first').length === 0) {
      return;
    }

    hash = window.location.hash;
    if (hash !== undefined && hash.length > 0 && !(/^#\//).test(hash)) {
      $('.nav-tabs a[href=' + hash + ']').tab('show');
    } else {
      $('.nav-tabs a:first').tab('show');
    }
  }
};

$(document).on('turbolinks:load', function () {
  Tabs.openByHash();
});
