import { mount } from '@vue/test-utils'
import SmallLoader from 'frontend/components/SmallLoader'

describe('SmallLoader', () => {
  it('does not render Smallloader default', () => {
    const cmp = mount(SmallLoader)
    expect(cmp.find('span').exists()).toBe(false)
  })

  it('renders Smallloader', () => {
    const cmp = mount(SmallLoader, { propsData: { loading: true } })
    // cmp.loading = true
    expect(cmp.find('span').exists()).toBe(true)
  })
})
