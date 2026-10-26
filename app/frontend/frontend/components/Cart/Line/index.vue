<script lang="ts">
export default {
  name: "CartLine",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useCartCache } from "@/frontend/composables/useCartCache";
import debounce from "lodash.debounce";
import { errorTypeFrom } from "@/shared/utils/ErrorTypes";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";
import {
  type CartLine,
  type ItemPrice,
  InventoryItemTypeEnum,
  useRemoveCartItem,
  useUpdateCartItem,
} from "@/services/fyApi";

type Props = {
  line: CartLine;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const { updateCart } = useCartCache();

const { displayAlert } = useAppNotifications();

const DETAIL_ROUTES: Record<InventoryItemTypeEnum, string> = {
  [InventoryItemTypeEnum.COMMODITY]: "commodity",
  [InventoryItemTypeEnum.COMPONENT]: "component",
  [InventoryItemTypeEnum.EQUIPMENT]: "equipment-item",
};

const itemRoute = computed(() => {
  const { item } = props.line;
  if (!item.listed || !item.slug || !item.type) return undefined;

  return { name: DETAIL_ROUTES[item.type], params: { slug: item.slug } };
});

// The server's cap; above it the save is refused.
const MAX_QUANTITY = 99_999;

const { mutate: update, isPending: updating } = useUpdateCartItem({
  mutation: {
    onSuccess: updateCart,
    onError: (error) => {
      // Gone already: its list was cleared before a pending save went out.
      if (errorTypeFrom(error) === ErrorTypesEnum.NOT_FOUND) return;

      quantity.value = props.line.quantity;
      displayAlert({ text: t("cart.messages.updateFailed") });
    },
  },
});

const { mutate: remove, isPending: removing } = useRemoveCartItem({
  mutation: {
    onSuccess: updateCart,
    onError: () => displayAlert({ text: t("cart.messages.updateFailed") }),
  },
});

const quantity = ref<number | string | null | undefined>(props.line.quantity);

// Follows the saved quantity only while the input still shows the previous
// one: an answer arriving mid-typing must not overwrite what is being typed.
watch(
  () => props.line.quantity,
  (value, previous) => {
    if (Number(quantity.value) === previous) {
      quantity.value = value;
    }
  },
);

const validQuantity = (value: number) =>
  Number.isInteger(value) && value >= 1 && value <= MAX_QUANTITY;

const saveQuantity = debounce(() => {
  const value = Number(quantity.value);
  if (!validQuantity(value) || value === props.line.quantity) {
    return;
  }

  update({ id: props.line.id, data: { quantity: value } });
}, 500);

watch(quantity, saveQuantity);

// Left alone while typing, since an empty field is on its way to a number;
// a value that cannot be saved goes back to the saved one on leaving.
const resetInvalidQuantity = () => {
  if (!validQuantity(Number(quantity.value))) {
    quantity.value = props.line.quantity;
  }
};

// A pin moves the line to another stop, which remounts it; a quantity typed
// just before is still sent.
onBeforeUnmount(() => saveQuantity.flush());

const removeLine = () => {
  saveQuantity.cancel();
  remove({ id: props.line.id });
};

const pin = (price: ItemPrice | null) => {
  update({ id: props.line.id, data: { itemPriceId: price?.id ?? null } });
};

// UEX names a terminal "shop - spaceport - city"; the shop is the part a
// buyer looks for once they have landed.
const shopName = (price: ItemPrice) =>
  price.shop?.name ?? price.location.split(" - ")[0];

const placeName = (price: ItemPrice) =>
  price.shop?.location.name ?? price.location.split(" - ").slice(1).join(" · ");

const uec = computed(() => t("number.units.uec"));

const formatPrice = (value?: number | null) =>
  value == null ? "" : `${toNumber(value, "integer")} ${uec.value}`;
</script>

<template>
  <div class="cart-line" data-test="cart-line">
    <div class="cart-line__item">
      <router-link v-if="itemRoute" :to="itemRoute" class="cart-line__name">
        {{ line.item.name }}
      </router-link>
      <span v-else class="cart-line__name">{{ line.item.name }}</span>
      <span v-if="line.price" class="cart-line__shop">
        {{ shopName(line.price) }}
        <Pill v-if="line.pinned" variant="neutral">{{ t("cart.pinned") }}</Pill>
        <Pill v-else-if="!line.cheapest" variant="neutral">
          {{ t("cart.tripPick") }}
        </Pill>
      </span>
    </div>

    <div class="cart-line__quantity" @focusout="resetInvalidQuantity">
      <FormInput
        v-model="quantity"
        :name="`cart-quantity-${line.id}`"
        type="number"
        :min="1"
        :max="MAX_QUANTITY"
        :step="1"
        :label="t('cart.quantity')"
        no-label
        standalone
        data-test="cart-line-quantity"
      />
    </div>

    <div class="cart-line__price">
      <template v-if="line.available">
        <span class="cart-line__total" data-test="cart-line-total">
          {{ formatPrice(line.total) }}
        </span>
        <small class="cart-line__unit">
          {{ t("cart.unitPrice", { price: formatPrice(line.unitPrice) }) }}
        </small>
      </template>
    </div>

    <div class="cart-line__actions">
      <BtnDropdown
        v-if="line.offers.length > 1 || line.pinned"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        expand-left
        data-test="cart-line-places"
      >
        <template #label>
          <i class="fa-light fa-location-dot" />
          <span class="sr-only">{{ t("cart.buyElsewhere") }}</span>
        </template>
        <Btn
          v-if="line.pinned"
          :variant="BtnVariantsEnum.BARE"
          :disabled="updating"
          @click="pin(null)"
        >
          {{ t("cart.cheapest") }}
        </Btn>
        <Btn
          v-for="offer in line.offers"
          :key="offer.id"
          :variant="BtnVariantsEnum.BARE"
          :disabled="updating || offer.id === line.price?.id"
          @click="pin(offer)"
        >
          {{ shopName(offer) }}
          <template v-if="placeName(offer)"> · {{ placeName(offer) }}</template>
          — {{ formatPrice(offer.price) }}
        </Btn>
      </BtnDropdown>
      <Btn
        v-tooltip.bottom="t('cart.remove')"
        :size="BtnSizesEnum.SM"
        :variant="BtnVariantsEnum.BARE"
        :loading="removing"
        :aria-label="t('cart.remove')"
        data-test="cart-line-remove"
        @click="removeLine"
      >
        <i class="fa-light fa-trash" />
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.cart-line {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 96px minmax(110px, auto) auto;
  gap: 12px;
  align-items: center;
  padding: 8px 0;

  & + & {
    border-top: 1px solid var(--color-edge-soft);
  }

  @media (max-width: $desktop-breakpoint) {
    grid-template-columns: minmax(0, 1fr) 80px;

    .cart-line__price {
      text-align: left;
    }
  }
}

.cart-line__item {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.cart-line__name {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.cart-line__shop,
.cart-line__unit {
  color: var(--color-text-dim);
}

.cart-line__shop {
  display: flex;
  gap: 6px;
  align-items: center;
  font-size: 0.9em;
}

.cart-line__price {
  display: flex;
  flex-direction: column;
  text-align: right;
}

.cart-line__total {
  font-variant-numeric: tabular-nums;
}

.cart-line__actions {
  display: flex;
  gap: 4px;
  justify-content: flex-end;
}
</style>
