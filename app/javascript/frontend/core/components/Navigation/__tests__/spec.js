import mountVM from 'helpers/mount'
import Navigation from 'frontend/core/components/Navigation'

describe('Navigation', () => {
  let cmp

  beforeEach(() => {
    cmp = mountVM(Navigation)
  })

  it('renders nothing without pagination info', () => {
    expect(cmp.findAll('nav')).toHaveLength(1)
  })
})
