<template>
  <div class="item-amount noselect">
    <i
      class="fal fa-minus"
      :class="{
        disabled: cartItem.amount <= 0,
      }"
      @click="cartItem.amount <= 0 ? () => {} : reduceAmount(cartItem.id)"
    />
    <span>
      {{ cartItem.amount }}
      <i class="fal fa-times" />
    </span>
    <i class="fal fa-plus" @click="increaseAmount(cartItem.id)" />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { Action } from 'vuex-class'

@Component<ShoppingCartItemAmount>({})
export default class ShoppingCartItemAmount extends Vue {
  @Prop({ required: true }) cartItem!: CartItem

  @Action('reduceAmount', { namespace: 'shoppingCart' }) reduceAmount: any

  @Action('increaseAmount', { namespace: 'shoppingCart' }) increaseAmount: any
}
</script>
