<script lang="ts">
export default {
  name: "CartAddToCart",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import CartListMenu from "@/frontend/components/Cart/ListMenu/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useCartCache } from "@/frontend/composables/useCartCache";
import {
  FeatureFlagName,
  type InventoryItemTypeEnum,
  useAddCartItem,
} from "@/services/fyApi";

type Props = {
  item: { id: string; type: InventoryItemTypeEnum; name: string };
  variant?: "default" | "row";
};

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
});

const { t } = useI18n();

const sessionStore = useSessionStore();

const { isFeatureEnabled } = useFeatures();

const { updateCart } = useCartCache();

const { displaySuccess, displayAlert, displayWarning } = useAppNotifications();

const enabled = computed(() => isFeatureEnabled(FeatureFlagName.SHOPPING_CART));

const btnVariant = computed(() =>
  props.variant === "row" ? BtnVariantsEnum.BARE : BtnVariantsEnum.GHOST,
);

const btnSize = computed(() =>
  props.variant === "row" ? BtnSizesEnum.SM : BtnSizesEnum.MD,
);

const { mutate, isPending } = useAddCartItem({
  mutation: {
    onSuccess: (cart) => {
      updateCart(cart);
      displaySuccess({
        text: t("cart.messages.added", {
          name: props.item.name,
          list: cart.name,
        }),
      });
    },
    onError: () => {
      displayAlert({ text: t("cart.messages.addFailed") });
    },
  },
});

// Without a list named, the item goes to the active one.
const add = (cartId?: string) => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({ text: t("cart.messages.accountRequired") });

    return;
  }

  mutate({
    data: {
      itemType: props.item.type,
      itemId: props.item.id,
      quantity: 1,
      cartId,
    },
  });
};
</script>

<!-- Adds one at a time; the quantity is set on the cart page, where the
     total it changes is in view. -->
<template>
  <BtnGroup v-if="enabled" class="cart-add-to-cart">
    <Btn
      v-tooltip.bottom="variant === 'row' ? t('cart.addToCart') : undefined"
      :variant="btnVariant"
      :size="btnSize"
      :loading="isPending"
      :aria-label="t('cart.addToCart')"
      data-test="cart-add"
      @click.stop.prevent="add()"
    >
      <i class="fa-light fa-cart-plus" />
      <template v-if="variant !== 'row'">{{ t("cart.addToCart") }}</template>
    </Btn>
    <CartListMenu :size="btnSize" :variant="btnVariant" @pick="add" />
  </BtnGroup>
</template>
