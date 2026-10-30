<script lang="ts">
export default {
  name: "FrontendCartNav",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { useCart } from "@/services/fyApi";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const sessionStore = useSessionStore();

const { isAuthenticated } = storeToRefs(sessionStore);

const enabled = computed(() => isAuthenticated.value);

// Shares the cart page's query, so an edit there or an item added from a
// catalogue moves the badge without a request of its own.
const { data: cart } = useCart(undefined, { query: { enabled } });

const badge = computed(() => cart.value?.totals.quantity || 0);
</script>

<template>
  <NavItem
    v-if="enabled"
    menu-key="cart"
    :label="t('nav.cart')"
    icon="fa-light fa-cart-shopping"
    :badge="badge"
    :to="{ name: 'cart' }"
    data-test="cart-nav"
  />
</template>
