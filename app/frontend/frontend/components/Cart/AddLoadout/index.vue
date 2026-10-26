<script lang="ts">
export default {
  name: "CartAddLoadout",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useCartCache } from "@/frontend/composables/useCartCache";
import {
  type CartItemCreateInput,
  FeatureFlagName,
  useAddCartItems,
  useCartLists,
} from "@/services/fyApi";

type Props = {
  // The parts to add, from `nonStockCartItems` or `nonStockFittedItems`.
  items?: CartItemCreateInput[];
};

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
});

const { t } = useI18n();

const sessionStore = useSessionStore();

const comlink = useComlink();

const { isFeatureEnabled } = useFeatures();

const { updateCart } = useCartCache();

const { displaySuccess, displayAlert, displayWarning } = useAppNotifications();

const featureEnabled = computed(() =>
  isFeatureEnabled(FeatureFlagName.SHOPPING_CART),
);

const enabled = computed(() => featureEnabled.value && props.items.length > 0);

const { data: lists } = useCartLists({
  query: {
    enabled: () => featureEnabled.value && sessionStore.isAuthenticated,
  },
});

const { mutate, isPending } = useAddCartItems({
  mutation: {
    onSuccess: (cart) => {
      updateCart(cart);
      displaySuccess({
        text: t("cart.messages.loadoutAdded", {
          count: props.items.reduce(
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

const add = () => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({ text: t("cart.messages.accountRequired") });

    return;
  }

  if ((lists.value?.length ?? 0) > 1) {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Cart/PickListModal/index.vue"),
      props: { name: t("cart.pick.loadoutParts"), items: props.items },
    });

    return;
  }

  mutate({ data: { items: props.items } });
};
</script>

<template>
  <Btn
    v-if="enabled"
    :size="BtnSizesEnum.MD"
    :loading="isPending"
    mobile-icon-only
    data-test="cart-add-loadout"
    @click="add"
  >
    <i class="fa-light fa-cart-plus" />
    {{ t("cart.addLoadout") }}
  </Btn>
</template>
