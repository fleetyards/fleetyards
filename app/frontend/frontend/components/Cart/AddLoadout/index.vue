<script lang="ts">
export default {
  name: "CartAddLoadout",
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
import { nonStockCartItems } from "@/frontend/utils/loadoutCartItems";
import {
  FeatureFlagName,
  type LoadoutSlot,
  useAddCartItems,
} from "@/services/fyApi";

type Props = {
  slots?: LoadoutSlot[];
};

const props = withDefaults(defineProps<Props>(), {
  slots: undefined,
});

const { t } = useI18n();

const sessionStore = useSessionStore();

const { isFeatureEnabled } = useFeatures();

const { updateCart } = useCartCache();

const { displaySuccess, displayAlert, displayWarning } = useAppNotifications();

const items = computed(() => nonStockCartItems(props.slots));

const enabled = computed(
  () =>
    isFeatureEnabled(FeatureFlagName.SHOPPING_CART) && items.value.length > 0,
);

const { mutate, isPending } = useAddCartItems({
  mutation: {
    onSuccess: (cart) => {
      updateCart(cart);
      displaySuccess({
        text: t("cart.messages.loadoutAdded", {
          count: items.value.reduce(
            (sum, item) => sum + (item.quantity ?? 1),
            0,
          ),
          list: cart.name,
        }),
      });
    },
    onError: () => {
      displayAlert({ text: t("cart.messages.addFailed") });
    },
  },
});

// Without a list named, the parts go to the active one.
const add = (cartId?: string) => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({ text: t("cart.messages.accountRequired") });

    return;
  }

  mutate({ data: { items: items.value, cartId } });
};
</script>

<template>
  <BtnGroup v-if="enabled" :size="BtnSizesEnum.MD">
    <Btn
      :loading="isPending"
      mobile-icon-only
      data-test="cart-add-loadout"
      @click="add()"
    >
      <i class="fa-light fa-cart-plus" />
      {{ t("cart.addLoadout") }}
    </Btn>
    <CartListMenu :variant="BtnVariantsEnum.SOLID" @pick="add" />
  </BtnGroup>
</template>
