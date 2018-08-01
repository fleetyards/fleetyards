import ModelPanel from 'frontend/partials/Models/Panel'

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
    expect(cmp.vm.$el.querySelector('.panel')).toBeTruthy()
  })

  it('renders heading with ship name and manufacturer', () => {
    expect(cmp.vm.$el.querySelector('h2').textContent).toContain(model.name)
    expect(cmp.vm.$el.querySelector('h2').textContent).toContain(model.manufacturer.name)
  })
})
