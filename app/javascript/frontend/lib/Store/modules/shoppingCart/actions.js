import { sortBy } from 'frontend/lib/Helpers'

const createShoppingCartItem = (newItem, type) => {
  const soldAt = sortBy(
    (newItem.soldAt || []).map(item => ({
      id: item.id,
      price: item.sellPrice,
      shopName: item.shop.name,
      shopSlug: item.shop.slug,
      stationName: item.shop.station.name,
      stationSlug: item.shop.station.slug,
    })),
    'price',
  )

  return {
    id: newItem.id,
    type,
    name: newItem.name,
    bestSoldAt: soldAt[0],
    soldAt,
    amount: 1,
  }
}

export default {
  reset({ commit }) {
    commit('reset')
  },

  reduceAmount({ commit, state }, itemId) {
    const foundItem = state.items.find(cartItem => cartItem.id === itemId)

    if (!foundItem || foundItem.amount <= 0) {
      return
    }

    commit(
      'setItems',
      state.items.map(cartItem => {
        if (cartItem.id !== foundItem.id) {
          return cartItem
        }

        return {
          ...foundItem,
          amount: foundItem.amount - 1,
        }
      }),
    )
  },

  increaseAmount({ commit, state }, itemId) {
    const foundItem = state.items.find(cartItem => cartItem.id === itemId)

    if (!foundItem) {
      return
    }

    commit(
      'setItems',
      state.items.map(cartItem => {
        if (cartItem.id !== foundItem.id) {
          return cartItem
        }

        return {
          ...foundItem,
          amount: foundItem.amount + 1,
        }
      }),
    )
  },

  add({ commit, state }, { item, type }) {
    const newItem = createShoppingCartItem(item, type)
    const foundItem = state.items.find(cartItem => cartItem.id === item.id)
    if (foundItem) {
      commit(
        'setItems',
        state.items.map(cartItem => {
          if (cartItem.id !== item.id) {
            return cartItem
          }

          return {
            ...newItem,
            amount: foundItem.amount + 1,
          }
        }),
      )
    } else {
      commit('add', newItem)
    }
  },

  update({ commit, state }, { item, type }) {
    const newItem = createShoppingCartItem(item, type)

    commit(
      'setItems',
      state.items.map(cartItem => {
        if (cartItem.id !== newItem.id) {
          return cartItem
        }

        return {
          ...newItem,
          amount: cartItem.amount,
        }
      }),
    )
  },

  remove({ commit, state }, cartItemId) {
    commit(
      'setItems',
      state.items.filter(cartItem => cartItem.id !== cartItemId),
    )
  },

  clear({ commit }) {
    commit('setItems', [])
  },
}
