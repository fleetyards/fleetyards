import ModelPanel from 'frontend/components/Models/Panel'
import Panel from 'frontend/core/components/Panel'
import mountVM from 'helpers/mount'

describe('ShipPanel', () => {
  let cmp
  let model

  beforeEach(() => {
    model = {
      name: 'Enterprise',
      slug: 'enterprise',
      storeImageMedium: 'TestImage',
      manufacturer: {
        name: 'Utopia Planitia',
      },
      shipRole: {
        name: 'Exporation Cruiser',
      },
    }
    cmp = mountVM(ModelPanel, { model })
  })

  it('renders ship panel', () => {
    const panel = cmp.findComponent(Panel)
    expect(panel.exists()).toBe(true)
  })

  it('renders heading with ship name and manufacturer', () => {
    expect(cmp.vm.$el.querySelector('h2').textContent).toContain(model.name)
    expect(cmp.vm.$el.querySelector('h2').textContent).toContain(
      model.manufacturer.name
    )
  })
})
