<template>
  <Btn
    v-tooltip="t('actions.shoppingCart.add')"
    class="add-to-cart"
    variant="link"
    @click="shoppingCartStore.add(item, type)"
  >
    <i class="fal fa-cart-plus" />
  </Btn>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import type { ShoppingCartItemType } from "@/frontend/stores/shoppingCart";
import { SearchResultTypeEnum } from "@/services/fyAdminApi";
import { useI18n } from "@/frontend/composables/useI18n";
import { useShoppingCartStore } from "@/frontend/stores/shoppingCart";

type Props = {
  item: ShoppingCartItemType;
  type: SearchResultTypeEnum;
};

defineProps<Props>();

const { t } = useI18n();

const shoppingCartStore = useShoppingCartStore();
</script>

<script lang="ts">
export default {
  name: "AddToCartBtn",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
