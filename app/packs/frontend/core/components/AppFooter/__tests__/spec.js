import mountVM from 'helpers/mount'
import AppFooter from 'frontend/core/components/AppFooter'

describe('AppFooter', () => {
  it('renders all links', () => {
    const cmp = mountVM(AppFooter)
    expect(cmp.findAll('a')).toHaveLength(10)
  })
})
