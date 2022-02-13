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

<script>
import { mapActions } from 'vuex'

export default {
  name: 'ShoppingCartItemAmount',

  props: {
    cartItem: {
      type: Object,
      required: true,
    },
  },

  methods: {
    ...mapActions('shoppingCart', ['reduceAmount', 'increaseAmount']),
  },
}
</script>
