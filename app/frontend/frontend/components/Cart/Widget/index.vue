<script lang="ts">
export default {
  name: "CartWidget",
};
</script>

<script lang="ts" setup>
import { useLocalStorage } from "@vueuse/core";
import { storeToRefs } from "pinia";
import { useRoute } from "vue-router";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { FeatureFlagName, useCart } from "@/services/fyApi";

const PREVIEW_LINES = 4;

const { t, toNumber } = useI18n();

const route = useRoute();

const mobile = useMobile();

const { isAuthenticated } = storeToRefs(useSessionStore());

const { isFeatureEnabled } = useFeatures();

const enabled = computed(
  () =>
    isAuthenticated.value && isFeatureEnabled(FeatureFlagName.SHOPPING_CART),
);

// The badge's query, so the widget costs no request of its own.
const { data: cart } = useCart(undefined, { query: { enabled } });

// A pill until opened, so it never covers a page uninvited.
const collapsed = useLocalStorage("fy-cart-widget-collapsed", true);

// The cart page shows all of this already.
const visible = computed(
  () => enabled.value && route.name !== "cart" && !!cart.value?.items.length,
);

const preview = computed(() =>
  (cart.value?.items ?? []).slice(0, PREVIEW_LINES),
);

const more = computed(
  () => (cart.value?.items.length ?? 0) - preview.value.length,
);

const uec = computed(() => t("number.units.uec"));
</script>

<template>
  <transition name="fade">
    <div
      v-if="visible && cart"
      class="cart-widget"
      :class="{ 'cart-widget--mobile': mobile }"
      data-test="cart-widget"
    >
      <button
        v-if="collapsed"
        type="button"
        class="cart-widget__pill"
        :aria-label="t('cart.widget.expand')"
        data-test="cart-widget-expand"
        @click="collapsed = false"
      >
        <i class="fa-light fa-cart-shopping" />
        <span class="cart-widget__count">{{ cart.totals.quantity }}</span>
        <span class="cart-widget__total">
          {{ toNumber(cart.totals.total, "integer") }} {{ uec }}
        </span>
        <i class="fa-light fa-chevron-up" />
      </button>

      <div v-else class="cart-widget__panel">
        <div class="cart-widget__header">
          <i class="fa-light fa-cart-shopping" />
          <span class="cart-widget__name">
            {{ cart.name || t("cart.title") }}
          </span>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            :aria-label="t('cart.widget.collapse')"
            data-test="cart-widget-collapse"
            @click="collapsed = true"
          >
            <i class="fa-light fa-chevron-down" />
          </Btn>
        </div>

        <ul class="cart-widget__lines">
          <li v-for="line in preview" :key="line.id" class="cart-widget__line">
            <span class="cart-widget__line-name">
              {{ line.quantity }} × {{ line.item.name }}
            </span>
            <span v-if="line.available" class="cart-widget__line-total">
              {{ toNumber(line.total ?? 0, "integer") }}
            </span>
            <span v-else class="cart-widget__line-total cart-widget__muted">
              {{ t("cart.widget.unavailable") }}
            </span>
          </li>
          <li v-if="more > 0" class="cart-widget__muted">
            {{ t("cart.widget.more", { count: more }) }}
          </li>
        </ul>

        <div class="cart-widget__sum">
          <span>{{ t("cart.totals.total") }}</span>
          <span class="cart-widget__total" data-test="cart-widget-total">
            {{ toNumber(cart.totals.total, "integer") }} {{ uec }}
          </span>
        </div>

        <router-link
          :to="{ name: 'cart' }"
          class="cart-widget__open"
          data-test="cart-widget-open"
        >
          {{ t("cart.widget.open") }}
        </router-link>
      </div>
    </div>
  </transition>
</template>

<style lang="scss" scoped>
// Centred rather than in a corner: the bottom right belongs to the hangar's
// add button and the sync cards. Above those (1025, 1040), below AppModal (1050).
.cart-widget {
  position: fixed;
  bottom: calc(20px + env(safe-area-inset-bottom));
  left: 50%;
  z-index: 1045;
  width: min(360px, calc(100vw - 32px));
  transform: translateX(-50%);
  pointer-events: none;

  > * {
    pointer-events: auto;
  }
}

// Above the mobile navigation, which is fixed along the bottom edge.
.cart-widget--mobile {
  bottom: calc(
    #{$navigation-mobile-height + $navigation-mobile-bottom-offset + 12px} +
      env(safe-area-inset-bottom)
  );
}

.cart-widget__pill {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-inline: auto;
  padding: 8px 16px;
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: 999px;
  background: var(--color-gray-darker, #272b30);
  box-shadow: 0 8px 24px rgb(0 0 0 / 0.45);
  color: var(--color-text);
}

.cart-widget__count {
  font-weight: 700;
}

.cart-widget__total {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

// The item overlay's surface (Popover), so the footer link meets the same
// rounded, clipped edge it does there.
.cart-widget__panel {
  overflow: hidden;
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-control, 8px);
  background: var(--color-gray-darker, #272b30);
  box-shadow: 0 8px 24px rgb(0 0 0 / 0.45);
}

.cart-widget__header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 12px;
}

.cart-widget__name {
  flex: 1 1 auto;
  min-width: 0;
  overflow: hidden;
  font-weight: 700;
  text-overflow: ellipsis;
  white-space: nowrap;
}

// Lined up with the line totals above it.
.cart-widget__sum {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  margin: 6px 12px 0;
  padding: 8px 0 10px;
  border-top: 1px solid var(--color-edge);
  font-weight: 700;
}

// The item overlay's footer link (StatsCard's `__link`): a menu's last row
// spanning the panel rather than a button.
.cart-widget__open {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 44px;
  padding: 0 16px;
  border-top: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  background: rgb(0 0 0 / 0.2);
  color: var(--color-primary, #428bca);
  font-size: 0.85rem;
  font-weight: 600;
  text-decoration: none;
  transition:
    background 150ms ease,
    color 150ms ease;

  &:hover,
  &:focus-visible {
    background: color-mix(
      in srgb,
      var(--color-primary, #428bca) 16%,
      transparent
    );
    color: var(--color-lifted, #eee);
    text-decoration: none;
  }

  &:focus-visible {
    outline: 2px solid var(--color-primary, #428bca);
    outline-offset: -2px;
  }
}

.cart-widget__lines {
  margin: 0;
  padding: 0 12px;
  list-style: none;
}

.cart-widget__line {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  padding: 2px 0;
}

.cart-widget__line-name {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.cart-widget__line-total {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.cart-widget__muted {
  color: var(--color-text-dim);
}
</style>
