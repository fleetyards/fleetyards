import { sortBy } from 'frontend/lib/Helpers'

export default {
  reset({ commit }) {
    commit('reset')
  },

  add({ commit }, { item, type }) {
    const soldAt = sortBy(item.soldAt || [], 'sellPrice')

    commit('add', {
      id: item.id,
      type,
      name: item.name,
      bestSoldAt: soldAt[0],
      soldAt,
    })
  },

  update({ commit, state }, { item: newItem, type }) {
    const soldAt = sortBy(newItem.soldAt || [], 'sellPrice')

    commit(
      'setItems',
      state.items.map(item => {
        if (item.id !== newItem.id) {
          return item
        }

        return {
          id: newItem.id,
          type,
          name: newItem.name,
          bestSoldAt: soldAt[0],
          soldAt,
        }
      }),
    )
  },

  remove({ commit }, payload) {
    commit('remove', payload)
  },

  clear({ commit }) {
    commit('setItems', [])
  },
}
