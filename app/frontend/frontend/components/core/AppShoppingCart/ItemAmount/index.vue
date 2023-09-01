<template>
  <div class="item-amount noselect">
    <i
      class="fal fa-minus"
      :class="{
        disabled: cartItem.amount <= 0,
      }"
      @click="
        cartItem.amount <= 0
          ? () => {}
          : shoppingCartStore.reduceAmount(cartItem.id)
      "
    />
    <span>
      {{ cartItem.amount }}
      <i class="fal fa-times" />
    </span>
    <i
      class="fal fa-plus"
      @click="shoppingCartStore.increaseAmount(cartItem.id)"
    />
  </div>
</template>

<script lang="ts" setup>
import { useShoppingCartStore } from "@/frontend/stores/shoppingCart";
import type { ShoppingCartItem } from "@/frontend/stores/shoppingCart";

type Props = {
  cartItem: ShoppingCartItem;
};

defineProps<Props>();

const shoppingCartStore = useShoppingCartStore();
</script>

<script lang="ts">
export default {
  name: "ShoppingCartItemAmount",
};
</script>
