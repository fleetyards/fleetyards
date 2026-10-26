<script lang="ts">
export default {
  name: "CartAddToCart",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useCartCache } from "@/frontend/composables/useCartCache";
import {
  FeatureFlagName,
  type InventoryItemTypeEnum,
  useAddCartItem,
  useCartLists,
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

const comlink = useComlink();

const { isFeatureEnabled } = useFeatures();

const { updateCart } = useCartCache();

const { displaySuccess, displayAlert, displayWarning } = useAppNotifications();

const enabled = computed(() => isFeatureEnabled(FeatureFlagName.SHOPPING_CART));

// One request however many buttons a page has: they share the query.
const { data: lists } = useCartLists({
  query: { enabled: () => enabled.value && sessionStore.isAuthenticated },
});

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

// With one list there is nothing to choose, so the click adds right away.
const add = () => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({ text: t("cart.messages.accountRequired") });

    return;
  }

  if ((lists.value?.length ?? 0) > 1) {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Cart/PickListModal/index.vue"),
      props: {
        name: props.item.name,
        items: [{ itemType: props.item.type, itemId: props.item.id }],
      },
    });

    return;
  }

  mutate({
    data: { itemType: props.item.type, itemId: props.item.id, quantity: 1 },
  });
};
</script>

<!-- The blueprint bookmark's twin: bare, an icon alone, wherever it sits. One
     at a time; the quantity is set on the cart page, where the total it
     changes is in view. -->
<template>
  <Btn
    v-if="enabled"
    v-tooltip.bottom="t('cart.addToCart')"
    :variant="BtnVariantsEnum.BARE"
    :size="btnSize"
    :loading="isPending"
    :aria-label="t('cart.addToCart')"
    data-test="cart-add"
    @click.stop.prevent="add"
  >
    <i class="fa-light fa-cart-plus" />
  </Btn>
</template>
