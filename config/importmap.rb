# frozen_string_literal: true

pin 'admin', preload: true
pin 'highcharts-options', preload: true
pin_all_from 'app/javascript/admin-app', under: 'admin-app'
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin "popper", to: 'popper.js', preload: true
pin "bootstrap", to: 'bootstrap.min.js', preload: true
pin 'highcharts', to: 'https://ga.jspm.io/npm:highcharts@9.3.2/highcharts.js'
pin 'axios', to: 'https://ga.jspm.io/npm:axios@0.21.4/index.js'
pin '#lib/adapters/http.js', to: 'https://ga.jspm.io/npm:axios@0.21.4/lib/adapters/xhr.js'
pin 'process', to: 'https://ga.jspm.io/npm:@jspm/core@2.0.0-beta.14/nodelibs/browser/process-production.js'
pin 'noty', to: 'https://ga.jspm.io/npm:noty@3.2.0-beta-deprecated/lib/noty.js'
pin 'ladda', to: 'https://ga.jspm.io/npm:ladda@2.0.3/js/ladda.js'
pin 'spin.js', to: 'https://ga.jspm.io/npm:spin.js@4.1.1/spin.js'
