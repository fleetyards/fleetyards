import Box from 'frontend/components/Box'

describe('Box', () => {
  let cmp
  beforeEach(() => {
    cmp = mountVM(Box)
  })

  it('renders', () => {
    expect(cmp.vm.$el.className).toBe('box')
  })

  it('renders large box', () => {
    cmp.setProps({ large: true })
    expect(cmp.vm.$el.className).toBe('box box-large')
  })
})
