import Loader from 'frontend/components/Loader'

describe('Loader', () => {
  it('renders centered loader', () => {
    const cmp = mountVM(Loader)
    expect(cmp.vm.$el.className).toBe('text-center')
    expect(cmp.vm.$el.querySelector('.loader')).not.toBeNull()
  })
})
