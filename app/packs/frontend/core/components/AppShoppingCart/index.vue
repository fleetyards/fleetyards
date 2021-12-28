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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import { sum as sumArray } from 'frontend/utils/Array'

@Component<ShoppingCart>({
  components: {
    Btn,
  },
})
export default class ShoppingCart extends Vue {
  @Getter('navSlim', { namespace: 'app' }) navSlim: boolean

  @Getter('items', { namespace: 'shoppingCart' }) cartItems: any[]

  get total() {
    return sumArray(
      this.cartItems.map((item) => this.sum(item)).filter((item) => item)
    )
  }

  get cartItemCount() {
    return sumArray(this.cartItems.map((item) => item.amount))
  }

  sum(cartItem) {
    return parseFloat((cartItem.bestSoldAt?.price || 0) * cartItem.amount)
  }

  openModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/core/components/AppShoppingCart/Modal'),
      wide: true,
    })
  }
}
</script>
