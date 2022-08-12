import Loader from '@/frontend/core/components/Loader/index.vue'
import sanityTest from '~/test/javascript/unit/sanityTest'
import { mount } from '@vue/test-utils'

sanityTest(Loader, {})

describe('Loader', () => {
  it('does not render loader on default', () => {
    const cmp = mount(Loader)
    expect(cmp.find('div').exists()).toBe(false)
  })

  it('renders centered loader', () => {
    const cmp = mount(Loader, { propsData: { loading: true } })
    const mainElement = cmp.find('div')

    expect(mainElement.exists()).toBe(true)
    expect(mainElement.classes('loader')).toBe(true)
    expect(cmp.find('.loader').exists()).toBe(true)
  })
})
