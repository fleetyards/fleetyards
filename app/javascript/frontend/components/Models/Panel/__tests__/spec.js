import ModelPanel from 'frontend/partials/Models/Panel'
import Panel from 'frontend/components/Panel'
import mountVM from 'helpers/mount'

describe('ShipPanel', () => {
  let cmp
  let model

  beforeEach(() => {
    model = {
      name: 'Enterprise',
      slug: 'enterprise',
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
    const panel = cmp.find(Panel)
    expect(panel.is(Panel)).toBe(true)
  })

  it('renders heading with ship name and manufacturer', () => {
    expect(cmp.vm.$el.querySelector('h2').textContent).toContain(model.name)
    expect(cmp.vm.$el.querySelector('h2').textContent).toContain(model.manufacturer.name)
  })
})
