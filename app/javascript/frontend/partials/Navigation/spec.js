import Navigation from 'frontend/partials/Navigation'

describe('Navigation', () => {
  let cmp

  beforeEach(() => {
    cmp = mountVM(Navigation)
  })

  it('renders nothing without pagination info', () => {
    expect(cmp.vm.$el.className).toContain('navbar')
  })
})
