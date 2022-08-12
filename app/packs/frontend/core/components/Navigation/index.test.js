import mountVM from '~/test/javascript/unit/mount'
import sanityTest from '~/test/javascript/unit/sanityTest'
import Navigation from '@/frontend/core/components/Navigation/index.vue'

sanityTest(Navigation)

describe('Navigation', () => {
  let cmp

  beforeEach(() => {
    cmp = mountVM(Navigation)
  })

  it('renders nothing without pagination info', () => {
    expect(cmp.findAll('nav')).toHaveLength(1)
  })
})
