import Loader from 'frontend/components/Loader'

describe('Loader', () => {
  it('does not render loader on default', () => {
    const cmp = mountVM(Loader)
    expect(cmp.vm.$el.innerHTML).toBeUndefined()
  })

  it('renders centered loader', () => {
    const cmp = mountVM(Loader, { loading: true })
    expect(cmp.vm.$el.className).toBe('text-center')
    expect(cmp.vm.$el.querySelector('.loader')).not.toBeNull()
  })
})
