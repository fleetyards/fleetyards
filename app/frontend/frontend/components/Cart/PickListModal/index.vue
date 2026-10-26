<script lang="ts">
export default {
  name: "CartPickListModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useCartCache } from "@/frontend/composables/useCartCache";
import {
  type CartItemCreateInput,
  type CartList,
  useAddCartItems,
  useCartLists,
} from "@/services/fyApi";

type Props = {
  // What the modal says it adds: an item's name, or a loadout's.
  name: string;
  items: CartItemCreateInput[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const { updateCart } = useCartCache();

const { displaySuccess, displayAlert } = useAppNotifications();

const { data: lists } = useCartLists();

// The active list first: it is where a single list's click would have gone.
const choices = computed(() =>
  [...(lists.value ?? [])].sort((a, b) => Number(b.active) - Number(a.active)),
);

const { mutate, isPending } = useAddCartItems({
  mutation: {
    onSuccess: (cart) => {
      updateCart(cart);
      const count = props.items.reduce(
        (sum, item) => sum + (item.quantity ?? 1),
        0,
      );
      displaySuccess({
        text:
          props.items.length === 1 && count === 1
            ? t("cart.messages.added", { name: props.name, list: cart.name })
            : t("cart.messages.loadoutAdded", { count, list: cart.name }),
      });
      comlink.emit("close-modal", true);
    },
    onError: () => displayAlert({ text: t("cart.messages.addFailed") }),
  },
});

const choose = (list: CartList) => {
  mutate({ data: { items: props.items, cartId: list.id } });
};
</script>

<template>
  <Modal :title="t('cart.pick.title', { name })" :loading="isPending">
    <div class="add-to-hangar-choices">
      <button
        v-for="list in choices"
        :key="list.id"
        type="button"
        class="add-to-hangar-choice"
        :disabled="isPending"
        :data-test="`cart-pick-${list.id}`"
        @click="choose(list)"
      >
        <i
          :class="[
            list.active ? 'fa-light fa-cart-shopping' : 'fa-light fa-list',
            'add-to-hangar-choice__icon',
          ]"
        />
        <span class="add-to-hangar-choice__text">
          <span class="add-to-hangar-choice__title">{{ list.name }}</span>
          <span class="add-to-hangar-choice__hint">
            {{
              list.active
                ? t("cart.pick.activeHint", { count: list.itemsCount })
                : t("cart.pick.hint", { count: list.itemsCount })
            }}
          </span>
        </span>
      </button>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Models/AddToHangar/Modal/choices";
</style>
