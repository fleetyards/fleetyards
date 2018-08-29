import SmallLoader from 'frontend/components/SmallLoader'

describe('SmallLoader', () => {
  it('does not render Smallloader default', () => {
    const cmp = mountVM(SmallLoader)
    expect(cmp.vm.$el.innerHTML).toBeUndefined()
  })

  it('renders Smallloader', () => {
    const cmp = mountVM(SmallLoader, { loading: true })
    // cmp.loading = true
    expect(cmp.vm.$el).not.toBeNull()
  })
})
