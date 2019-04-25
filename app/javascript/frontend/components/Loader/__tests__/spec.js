import Loader from 'frontend/components/Loader'
import { mount } from '@vue/test-utils'

describe('Loader', () => {
  it('does not render loader on default', () => {
    const cmp = mount(Loader)
    expect(cmp.vm.$el.innerHTML).toBeUndefined()
  })

  it('renders centered loader', () => {
    const cmp = mount(Loader, { propsData: { loading: true } })
    expect(cmp.vm.$el.className).toBe('text-center')
    expect(cmp.vm.$el.querySelector('.loader')).not.toBeNull()
  })
})
