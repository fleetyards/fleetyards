import { mount } from 'vue/test-utils'
import Panel from 'frontend/components/Panel'

describe('Panel', () => {
  it('renders panel', () => {
    const cmp = mount(Panel)
    expect(cmp.vm.$el.className).toContain('panel')
  })
})
