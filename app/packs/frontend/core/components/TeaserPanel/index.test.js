import sanityTest from '~/test/javascript/unit/sanityTest'
import Component from '@/frontend/core/components/TeaserPanel/index.vue'

const item = {
  name: 'Enterprise',
  description: '',
  storeImage: 'TestImage',
  storeImageMedium: 'TestImage',
}

sanityTest(Component, { item })
