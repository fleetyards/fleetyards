<script lang="ts">
export default {
  name: "FleetShoppingListCopyModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useCartCache } from "@/frontend/composables/useCartCache";
import {
  type Fleet,
  type FleetShoppingList,
  useCartLists,
  useCopyFleetShoppingList,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  list: FleetShoppingList;
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const { updateCart, refreshCarts } = useCartCache();

const { displaySuccess, displayAlert } = useAppNotifications();

const { data: lists } = useCartLists();

const choices = computed(() =>
  [...(lists.value ?? [])].sort((a, b) => Number(b.active) - Number(a.active)),
);

const { mutate, isPending } = useCopyFleetShoppingList({
  mutation: {
    onSuccess: (cart) => {
      updateCart(cart);
      // A new list became the active one, so every list's flag changed.
      refreshCarts();
      displaySuccess({
        text: t("cart.fleetLists.messages.copied", {
          name: props.list.name,
          list: cart.name,
        }),
      });
      comlink.emit("close-modal", true);
    },
    onError: () =>
      displayAlert({ text: t("cart.fleetLists.messages.copyFailed") }),
  },
});

const copy = (cartId?: string) => {
  mutate({
    fleetSlug: props.fleet.slug,
    id: props.list.id,
    data: cartId ? { cartId } : {},
  });
};
</script>

<template>
  <Modal
    :title="t('cart.fleetLists.copyTitle', { name: list.name })"
    :loading="isPending"
  >
    <div class="add-to-hangar-choices">
      <button
        type="button"
        class="add-to-hangar-choice"
        :disabled="isPending"
        data-test="fleet-shopping-list-copy-new"
        @click="copy()"
      >
        <i class="fa-light fa-plus add-to-hangar-choice__icon" />
        <span class="add-to-hangar-choice__text">
          <span class="add-to-hangar-choice__title">
            {{ t("cart.fleetLists.copyNew") }}
          </span>
          <span class="add-to-hangar-choice__hint">
            {{ t("cart.fleetLists.copyNewHint", { name: list.name }) }}
          </span>
        </span>
      </button>
      <button
        v-for="cart in choices"
        :key="cart.id"
        type="button"
        class="add-to-hangar-choice"
        :disabled="isPending"
        :data-test="`fleet-shopping-list-copy-${cart.id}`"
        @click="copy(cart.id)"
      >
        <i
          :class="[
            cart.active ? 'fa-light fa-cart-shopping' : 'fa-light fa-list',
            'add-to-hangar-choice__icon',
          ]"
        />
        <span class="add-to-hangar-choice__text">
          <span class="add-to-hangar-choice__title">{{ cart.name }}</span>
          <span class="add-to-hangar-choice__hint">
            {{ t("cart.fleetLists.copyIntoHint", { count: cart.itemsCount }) }}
          </span>
        </span>
      </button>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/AddToHangar/Modal/choices";
</style>
