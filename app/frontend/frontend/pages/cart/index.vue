<script lang="ts">
export default {
  name: "CartPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import PageActions from "@/shared/components/PageActions/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import CartLine from "@/frontend/components/Cart/Line/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useCartCache } from "@/frontend/composables/useCartCache";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import { type CartLine as CartLineType, useCart, useClearCart } from "@/services/fyApi";

const { t, toNumber } = useI18n();

const { displayConfirm, displayAlert } = useAppNotifications();

const { updateCart } = useCartCache();

const { data: cart, isLoading } = useCart();

const { mutate: clear, isPending: clearing } = useClearCart({
  mutation: {
    onSuccess: updateCart,
    onError: () => displayAlert({ text: t("cart.messages.updateFailed") }),
  },
});

const confirmClear = () => {
  displayConfirm({
    text: t("cart.confirmClear"),
    tone: AppConfirmTonesEnum.DANGER,
    onConfirm: () => clear(),
  });
};

const linesById = computed(
  () =>
    new Map((cart.value?.items ?? []).map((line) => [line.id, line])),
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

  <PageActions v-if="cart?.items.length">
    <Btn
      :tone="BtnTonesEnum.DANGER"
      :loading="clearing"
      data-test="cart-clear"
      @click="confirmClear"
    >
      <i class="fa-light fa-trash" />
      {{ t("cart.clear") }}
    </Btn>
  </PageActions>

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
        :value="cart.totals.itemsCount"
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
        <CartLine v-for="line in group.lines" :key="line.id" :line="line" />
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
