<script lang="ts">
export default {
  name: "CartAddLoadout",
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
  type CartItemCreateInput,
  FeatureFlagName,
  useAddCartItems,
  useCartLists,
} from "@/services/fyApi";

type Props = {
  // The parts to add, from `nonStockCartItems` or `nonStockFittedItems`.
  items?: CartItemCreateInput[];
  // Inside a modal, which opening the list picker would replace: the button
  // asks which list where it stands instead.
  inModal?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  inModal: false,
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

const choosing = ref(false);

const addTo = (cartId: string) => {
  choosing.value = false;
  mutate({ data: { items: props.items, cartId } });
};

const add = () => {
  if (!sessionStore.isAuthenticated) {
    displayWarning({ text: t("cart.messages.accountRequired") });

    return;
  }

  if ((lists.value?.length ?? 0) > 1 && props.inModal) {
    choosing.value = true;

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
  <div
    v-if="enabled && choosing"
    class="cart-add-loadout__choices"
    data-test="cart-add-loadout-choices"
  >
    <span class="cart-add-loadout__question">
      {{ t("cart.pick.question") }}
    </span>
    <Btn
      v-for="list in lists"
      :key="list.id"
      :size="BtnSizesEnum.MD"
      :data-test="`cart-add-loadout-to-${list.id}`"
      @click="addTo(list.id)"
    >
      <i
        :class="list.active ? 'fa-light fa-cart-shopping' : 'fa-light fa-list'"
      />
      {{ list.name }}
    </Btn>
    <Btn
      :size="BtnSizesEnum.MD"
      :variant="BtnVariantsEnum.GHOST"
      :aria-label="t('actions.cancel')"
      data-test="cart-add-loadout-cancel"
      @click="choosing = false"
    >
      <i class="fa-light fa-xmark" />
    </Btn>
  </div>
  <Btn
    v-else-if="enabled"
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

<style lang="scss" scoped>
.cart-add-loadout__choices {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.cart-add-loadout__question {
  color: var(--color-text-dim);
}
</style>
