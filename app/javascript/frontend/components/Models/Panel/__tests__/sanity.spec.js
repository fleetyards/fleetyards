import sanityTest from 'helpers/sanityTest'
import Component from 'frontend/partials/Models/Panel'

const model = {
  name: 'Enterprise',
  slug: 'enterprise',
  manufacturer: {
    name: 'Utopia Planitia',
  },
  shipRole: {
    name: 'Exporation Cruiser',
  },
}

sanityTest(Component, { model })
