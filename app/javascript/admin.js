import '@hotwired/turbo-rails'
import 'highcharts-options'
import 'admin-app'

// $(document).on('show.bs.collapse', '.navbar-collapse', () => {
//   $('.navbar-collapse.in').not(this).collapse('hide')
// })

// $(document).on('focus', '.modal input, .modal textarea, .modal select', () => {
//   $(this)[0].scrollIntoView(true)
// })

window.addEventListener('turbo:before-render', () => {
  console.log('page load foo')
  // $('.btn.btn-primary[data-loading-text]').click(() => {
  //   $(this).button('loading')
  // })
})
