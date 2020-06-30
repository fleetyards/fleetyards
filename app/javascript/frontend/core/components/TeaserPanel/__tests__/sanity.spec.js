import sanityTest from 'helpers/sanityTest'
import Component from 'frontend/core/components/TeaserPanel'

const item = {
  name: 'Enterprise',
  description: '',
  storeImage: 'TestImage',
  storeImageMedium: 'TestImage',
}

sanityTest(Component, { item })
