<script lang="ts">
export default {
  name: "CartPage",
};
</script>

<script lang="ts" setup>
import { useRoute, useRouter } from "vue-router";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import CartLine from "@/frontend/components/Cart/Line/index.vue";
import CartListSelect from "@/frontend/components/Cart/ListSelect/index.vue";
import CartListActions from "@/frontend/components/Cart/ListActions/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type CartLine as CartLineType,
  CartStrategyEnum,
  useCart,
  useCartList,
} from "@/services/fyApi";

const { t, toNumber } = useI18n();

const route = useRoute();

const router = useRouter();

const comlink = useComlink();

// Any of the user's lists can be shown; without one named, the active list.
const listId = computed(() =>
  typeof route.query.list === "string" ? route.query.list : undefined,
);

const STRATEGY_ICONS: Record<CartStrategyEnum, string> = {
  [CartStrategyEnum.CHEAPEST]: "fa-light fa-coins",
  [CartStrategyEnum.STOPS]: "fa-light fa-location-dot",
  [CartStrategyEnum.DISTANCE]: "fa-light fa-route",
};

const strategy = computed(
  () =>
    Object.values(CartStrategyEnum).find(
      (value) => value === route.query.strategy,
    ) ?? CartStrategyEnum.CHEAPEST,
);

const params = computed(() => ({ strategy: strategy.value }));

const selectStrategy = (value: CartStrategyEnum) => {
  void router.replace({
    query: {
      ...route.query,
      strategy: value === CartStrategyEnum.CHEAPEST ? undefined : value,
    },
  });
};

const activeCart = useCart(params, {
  query: { enabled: () => !listId.value },
});

const listCart = useCartList(() => listId.value ?? "", params, {
  query: { enabled: () => !!listId.value },
});

// A list deleted in another tab, or a stale link: the active list instead.
watch(
  () => listCart.isError.value,
  (failed) => {
    if (failed) {
      void router.replace({ query: { ...route.query, list: undefined } });
    }
  },
);

const cart = computed(() =>
  listId.value ? listCart.data.value : activeCart.data.value,
);

const isLoading = computed(() =>
  listId.value ? listCart.isLoading.value : activeCart.isLoading.value,
);

const createList = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/Cart/ListModal/index.vue"),
  });
};

const linesById = computed(
  () => new Map((cart.value?.items ?? []).map((line) => [line.id, line])),
);

const groups = computed(() =>
  (cart.value?.groups ?? []).map((group) => ({
    ...group,
    lines: group.itemIds
      .map((id) => linesById.value.get(id))
      .filter((line): line is CartLineType => !!line),
  })),
);

const unavailable = computed(() =>
  (cart.value?.items ?? []).filter((line) => !line.available),
);

const uec = computed(() => t("number.units.uec"));
</script>

<template>
  <Heading size="hero" hero>{{ t("cart.title") }}</Heading>
  <p class="cart-lead">{{ t("cart.lead") }}</p>

  <Teleport to="#header-right">
    <CartListSelect :list-id="cart?.id" />
    <Btn
      :size="BtnSizesEnum.MD"
      mobile-icon-only
      data-test="cart-list-new"
      @click="createList"
    >
      <i class="fa-light fa-plus" />
      {{ t("cart.lists.create") }}
    </Btn>
  </Teleport>

  <CartListActions :list-id="cart?.id" :has-items="!!cart?.items.length">
    <BtnGroup segmented :size="BtnSizesEnum.MD" data-test="cart-strategy">
      <Btn
        v-for="value in Object.values(CartStrategyEnum)"
        :key="value"
        v-tooltip.bottom="t(`cart.strategies.${value}.hint`)"
        :active="strategy === value"
        mobile-icon-only
        :data-test="`cart-strategy-${value}`"
        @click="selectStrategy(value)"
      >
        <i :class="STRATEGY_ICONS[value]" />
        {{ t(`cart.strategies.${value}.label`) }}
      </Btn>
    </BtnGroup>
  </CartListActions>

  <Loader :loading="isLoading" />

  <template v-if="cart?.items.length">
    <div class="cart-totals">
      <StatsPanel
        :label="t('cart.totals.total')"
        icon="fa-duotone fa-coins"
        :outer-spacing="false"
        data-test="cart-total"
      >
        <template #value>
          {{ toNumber(cart.totals.total, "integer") }}
          <small>{{ uec }}</small>
        </template>
      </StatsPanel>
      <StatsPanel
        :label="t('cart.totals.items')"
        icon="fa-duotone fa-cart-shopping"
        :value="cart.totals.quantity"
        :outer-spacing="false"
      />
      <StatsPanel
        :label="t('cart.totals.stops')"
        icon="fa-duotone fa-location-dot"
        :value="cart.totals.stopsCount"
        :outer-spacing="false"
      />
      <StatsPanel
        v-if="cart.totals.unavailableCount"
        :label="t('cart.totals.unavailable')"
        icon="fa-duotone fa-ban"
        :value="cart.totals.unavailableCount"
        :outer-spacing="false"
      />
    </div>

    <Panel
      v-for="group in groups"
      :key="group.key"
      :variant="PanelVariantsEnum.SLIM"
      class="cart-stop"
      data-test="cart-stop"
    >
      <PanelHeading compact divider>
        <router-link
          v-if="group.location"
          :to="{ name: 'location', params: { slug: group.location.slug } }"
        >
          {{ group.name }}
        </router-link>
        <template v-else>{{ group.name || t("cart.unplaced") }}</template>
        <template #subtitle>
          <span v-if="group.systemName">{{ group.systemName }} · </span>
          {{ toNumber(group.subtotal, "integer") }} {{ uec }}
        </template>
      </PanelHeading>
      <PanelBody>
        <CartLine
          v-for="line in group.lines"
          :key="line.id"
          :line="line"
          :strategy="strategy"
        />
      </PanelBody>
    </Panel>

    <Panel
      v-if="unavailable.length"
      :variant="PanelVariantsEnum.SLIM"
      class="cart-stop"
      data-test="cart-unavailable"
    >
      <PanelHeading compact divider>
        {{ t("cart.unavailable.title") }}
        <template #subtitle>{{ t("cart.unavailable.text") }}</template>
      </PanelHeading>
      <PanelBody>
        <CartLine v-for="line in unavailable" :key="line.id" :line="line" />
      </PanelBody>
    </Panel>
  </template>

  <Empty v-else-if="!isLoading" variant="box" hide-actions>
    <template #headline>{{ t("cart.empty.title") }}</template>
    <template #info>
      <p>{{ t("cart.empty.text") }}</p>
    </template>
  </Empty>
</template>

<style lang="scss" scoped>
.cart-lead {
  max-width: 720px;
  color: var(--color-text-dim);
}

.cart-totals {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 16px;
  margin-bottom: 16px;
}

.cart-stop + .cart-stop {
  margin-top: 16px;
}
</style>
