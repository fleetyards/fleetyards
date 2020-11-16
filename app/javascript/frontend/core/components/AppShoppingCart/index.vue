<template>
  <Btn
    v-if="items.length && !mobile"
    class="app-shopping-cart"
    :class="{
      'nav-slim': navSlim,
    }"
    @click.native="openModal"
  >
    <i class="fad fa-shopping-cart" />
    <span
      class="items-label"
      v-html="
        $t('labels.shoppingCart.items', {
          count: items.length,
          price: $toUEC(price),
        })
      "
    />
  </Btn>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import { sum } from 'frontend/utils/Array'

@Component<ShoppingCart>({
  components: {
    Btn,
  },
})
export default class ShoppingCart extends Vue {
  @Getter('navSlim', { namespace: 'app' }) navSlim: boolean

  @Getter('items', { namespace: 'shoppingCart' }) items: any[]

  @Getter('mobile') mobile: boolean

  get sellPrices() {
    return this.items
      .map(item => item.bestSoldAt)
      .map(item => parseFloat(item?.sellPrice))
      .filter(item => item)
  }

  get price() {
    return sum(this.sellPrices)
  }

  openModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/core/components/AppShoppingCart/Modal'),
      wide: true,
    })
  }
}
</script>
