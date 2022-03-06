<template>
  <div
    class="app-shopping-cart"
    :class="{
      'nav-slim': navSlim,
    }"
  >
    <Btn v-if="cartItems.length" @click.native="openModal">
      <i class="fad fa-shopping-cart" />
      <span
        class="items-label"
        v-html="
          $t('labels.shoppingCart.items', {
            count: cartItemCount,
            price: $toUEC(total),
          })
        "
      />
    </Btn>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'
import { sum as sumArray } from '@/frontend/utils/Array'

export default {
  name: 'AppShoppingCart',
  components: {
    Btn,
  },

  computed: {
    ...mapGetters('app', ['navSlim']),

    ...mapGetters('shoppingCart', {
      cartItems: 'items',
    }),

    cartItemCount() {
      return sumArray(this.cartItems.map((item) => item.amount))
    },

    total() {
      return sumArray(
        this.cartItems.map((item) => this.sum(item)).filter((item) => item)
      )
    },
  },

  methods: {
    openModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/core/components/AppShoppingCart/Modal/index.vue'),
        wide: true,
      })
    },

    sum(cartItem) {
      return parseFloat((cartItem.bestSoldAt?.price || 0) * cartItem.amount)
    },
  },
}
</script>
