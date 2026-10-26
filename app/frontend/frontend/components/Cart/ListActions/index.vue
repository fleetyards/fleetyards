<script lang="ts">
export default {
  name: "CartListActions",
};
</script>

<script lang="ts" setup>
import { useRoute, useRouter } from "vue-router";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useCartCache } from "@/frontend/composables/useCartCache";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  type CartList,
  useCartLists,
  useClearCartList,
  useDestroyCartList,
  useUpdateCartList,
} from "@/services/fyApi";

type Props = {
  // The list the page shows, which need not be the active one.
  listId?: string | null;
  hasItems?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  listId: undefined,
  hasItems: false,
});

const { t } = useI18n();

const route = useRoute();

const router = useRouter();

const { displayConfirm, displayAlert } = useAppNotifications();

const comlink = useComlink();

const { refreshCarts, updateCart } = useCartCache();

const { data: lists } = useCartLists();

const shown = computed(() =>
  lists.value?.find((list) => list.id === props.listId),
);

const onError = () => displayAlert({ text: t("cart.messages.updateFailed") });

const { mutate: update, isPending: activating } = useUpdateCartList({
  mutation: { onSuccess: refreshCarts, onError },
});

const { mutate: destroy, isPending: deleting } = useDestroyCartList({
  mutation: {
    onSuccess: () => {
      refreshCarts();
      void router.replace({
        name: "cart",
        query: { strategy: route.query.strategy },
      });
    },
    onError,
  },
});

const activate = (list: CartList) => {
  update(
    { id: list.id, data: { active: true } },
    {
      onSuccess: () =>
        void router.replace({
          name: "cart",
          query: { strategy: route.query.strategy },
        }),
    },
  );
};

const openModal = (list?: CartList) => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/Cart/ListModal/index.vue"),
    props: { list },
  });
};

const { mutate: clear, isPending: clearing } = useClearCartList({
  mutation: { onSuccess: updateCart, onError },
});

const confirmClear = (list: CartList) => {
  displayConfirm({
    text: t("cart.confirmClear"),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: () => clear({ id: list.id }),
  });
};

const confirmDelete = (list: CartList) => {
  displayConfirm({
    text: t("cart.lists.confirmDelete", { name: list.name }),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: () => destroy({ id: list.id }),
  });
};
</script>

<template>
  <div class="cart-list-actions" data-test="cart-list-actions">
    <slot />

    <div v-if="shown" class="cart-list-actions__list">
      <Btn
        v-if="!shown.active"
        :loading="activating"
        data-test="cart-list-activate"
        @click="activate(shown)"
      >
        <i class="fa-light fa-circle-check" />
        {{ t("cart.lists.activate") }}
      </Btn>
      <span
        v-else
        class="cart-list-actions__active"
        data-test="cart-list-active"
      >
        <i class="fa-solid fa-circle-check" />
        {{ t("cart.lists.isActive") }}
      </span>

      <BtnDropdown expand-left data-test="cart-list-menu-actions">
        <Btn
          :size="BtnSizesEnum.SM"
          data-test="cart-list-rename"
          @click="openModal(shown)"
        >
          <i class="fa-light fa-pen" />
          {{ t("cart.lists.rename") }}
        </Btn>
        <Btn
          v-if="hasItems"
          :size="BtnSizesEnum.SM"
          :tone="BtnTonesEnum.DANGER"
          :loading="clearing"
          data-test="cart-clear"
          @click="confirmClear(shown)"
        >
          <i class="fa-light fa-broom" />
          {{ t("cart.clear") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.SM"
          :tone="BtnTonesEnum.DANGER"
          :loading="deleting"
          data-test="cart-list-delete"
          @click="confirmDelete(shown)"
        >
          <i class="fa-light fa-trash" />
          {{ t("cart.lists.delete") }}
        </Btn>
      </BtnDropdown>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.cart-list-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 16px;
}

// Pushed to the end of the row even when the plan control wraps above it.
.cart-list-actions__list {
  display: flex;
  margin-left: auto;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
}

.cart-list-actions__active {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  color: var(--color-success);
}
</style>
