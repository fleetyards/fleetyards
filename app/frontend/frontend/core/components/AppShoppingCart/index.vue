<template>
  <div
    class="app-shopping-cart"
    :class="{
      'nav-slim': navSlim,
    }"
  >
    <Btn v-if="cartItems.length" @click="openModal">
      <i class="fad fa-shopping-cart" />
      <span
        class="items-label"
        v-html="
          t('labels.shoppingCart.items', {
            count: cartItemCount,
            price: toUEC(total),
          })
        "
      />
    </Btn>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import { sum as sumArray } from "@/frontend/utils/Array";
import { useI18n } from "@/frontend/composables/useI18n";
import { useAppStore } from "@/frontend/stores/app";
import { useShoppingCartStore } from "@/frontend/stores/shoppingCart";
import type { ShoppingCartItem } from "@/frontend/stores/shoppingCart";
import { storeToRefs } from "pinia";
import { useComlink } from "@/shared/composables/useComlink";

const { t, toUEC } = useI18n();

const appStore = useAppStore();

const { navSlim } = storeToRefs(appStore);

const shoppingCartStore = useShoppingCartStore();

const { items: cartItems } = storeToRefs(shoppingCartStore);

const total = computed(() => {
  return sumArray(
    cartItems.value.map((item) => sum(item)).filter((item) => item),
  );
});

const cartItemCount = computed(() => {
  return sumArray(cartItems.value.map((item) => item.amount));
});

const sum = (cartItem: ShoppingCartItem) => {
  return parseFloat(
    String((cartItem.bestSoldAt?.price || 0) * cartItem.amount),
  );
};

const comlink = useComlink();

const openModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/core/components/AppShoppingCart/Modal/index.vue"),
    wide: true,
  });
};
</script>

<script lang="ts">
export default {
  name: "AppShoppingCart",
};
</script>
