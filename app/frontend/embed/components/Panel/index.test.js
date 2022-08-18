import mountVM from '~/test/javascript/unit/mount'
import Panel from '@/frontend/core/components/Panel/index.vue'

describe('Panel', () => {
  it('renders panel', () => {
    const cmp = mountVM(Panel)
    expect(cmp.vm.$el.className).toContain('panel')
  })
})
