import mountVM from 'helpers/mount'
import Panel from 'frontend/components/Panel'

describe('Panel', () => {
  it('renders panel', () => {
    const cmp = mountVM(Panel)
    expect(cmp.vm.$el.className).toContain('panel')
  })
})
