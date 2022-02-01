import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = [
    'body',
    'nav',
    'navHeadline',
    'navLogo',
    'navTitle',
    'navItem',
    'navItemLabel',
    'navItemIcon',
    'navUserNav',
  ]

  connect() {
    console.info('BaseController connect')

    this.setupSelect()

    window.addEventListener('click', this.setupDisabled)

    document.addEventListener('turbo:before-fetch-request', async (event) => {
      event.preventDefault()

      console.log('render', event.detail.url.search)

      // const token = await getSessionToken(window.app)
      // event.detail.fetchOptions.headers['Authorization'] = `Bearer ${token}`

      event.detail.resume()
    })
  }

  disconnect() {
    window.removeEventListener('click', this.setupDisabled)
  }

  setupDisabled(event) {
    const { target } = event

    if (
      target.classList.contains('disabled') ||
      target.getAttribute('disabled') === 'disabled'
    ) {
      event.stopPropagation()
      event.preventDefault()
    }
  }

  setupSelect() {
    // if $('select:not(.selectized)').length
    //   $('select:not(.selectized)').selectize()
  }

  collapseNavigation() {
    console.log('foo')
    this.navTarget.classList.remove('md:w-72')
    this.navTarget.classList.add('md:w-20')
    this.bodyTarget.classList.remove('md:pl-72')
    this.bodyTarget.classList.add('md:pl-20')
    this.navHeadlineTarget.classList.add('justify-center')
    this.navLogoTarget.classList.remove('mr-4')
    this.navTitleTarget.classList.add('hidden')
    this.navUserNavTarget.classList.add('justify-center')
    this.navItemTargets.forEach((navItem) => {
      navItem.classList.add('justify-center', 'px-3')
      navItem.classList.remove('text-left', 'pl-4', 'pr-2')
    })
    this.navItemLabelTargets.forEach((navItemLabel) => {
      navItemLabel.classList.add('hidden')
    })
    this.navItemIconTargets.forEach((navItemIcon) => {
      navItemIcon.classList.remove('mr-3')
    })

    localStorage.setItem('navigation', 'collapsed')
    setCookie('navigationCollapsed', true)
  }

  expandNavigation() {
    this.navTarget.classList.remove('md:w-20')
    this.navTarget.classList.add('md:w-72')
    this.bodyTarget.classList.remove('md:pl-20')
    this.bodyTarget.classList.add('md:pl-72')
    this.navHeadlineTarget.classList.remove('justify-center')
    this.navLogoTarget.classList.add('mr-4')
    this.navTitleTarget.classList.remove('hidden')
    this.navUserNavTarget.classList.remove('justify-center')
    this.navItemTargets.forEach((navItem) => {
      navItem.classList.remove('justify-center', 'px-3')
      navItem.classList.add('text-left', 'pl-4', 'pr-2')
    })
    this.navItemLabelTargets.forEach((navItemLabel) => {
      navItemLabel.classList.remove('hidden')
    })
    this.navItemIconTargets.forEach((navItemIcon) => {
      navItemIcon.classList.add('mr-3')
    })

    setCookie('navigationCollapsed', false)
  }
}
