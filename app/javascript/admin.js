import '@hotwired/turbo-rails'
import 'highcharts-options'
import 'admin-app'

// $(document).on('show.bs.collapse', '.navbar-collapse', () => {
//   $('.navbar-collapse.in').not(this).collapse('hide')
// })

// $(document).on('focus', '.modal input, .modal textarea, .modal select', () => {
//   $(this)[0].scrollIntoView(true)
// })

document.addEventListener('turbo:before-render', async (event) => {
  console.log('page load', event)
  // $('.btn.btn-primary[data-loading-text]').click(() => {
  //   $(this).button('loading')
  // })
})

document.addEventListener('turbo:before-fetch-request', async (event) => {
  event.preventDefault()

  console.log('render', event)

  // const token = await getSessionToken(window.app)
  // event.detail.fetchOptions.headers['Authorization'] = `Bearer ${token}`

  event.detail.resume()
})