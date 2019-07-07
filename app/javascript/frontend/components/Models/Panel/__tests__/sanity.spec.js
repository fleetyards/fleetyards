import sanityTest from 'helpers/sanityTest'
import Component from 'frontend/components/Models/Panel'

const model = {
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

sanityTest(Component, { model })
