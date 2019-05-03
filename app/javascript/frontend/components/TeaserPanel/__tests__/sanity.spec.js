import sanityTest from 'helpers/sanityTest'
import Component from 'frontend/components/TeaserPanel'

const item = {
  name: 'Enterprise',
  description: '',
  storeImage: '',
}

sanityTest(Component, { item })
