<script lang="ts">
export default {
  name: "TradeRoutesRunBar",
};
</script>

<script lang="ts" setup>
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import {
  TradeRoutePriceAgesEnum,
  useTradeRouteRun,
} from "@/frontend/composables/useTradeRouteRun";
import {
  type ModelExtended,
  useTradeRouteCommoditiesFilters,
  useTradeRouteStarSystemsFilters,
} from "@/services/fyApi";

type Props = {
  ship?: ModelExtended;
};

defineProps<Props>();

const emit = defineEmits<{
  "pick-ship": [];
}>();

const { t, toNumber } = useI18n();

const mobile = useMobile();

// On a phone the bar folds into one summary line: five stacked controls would
// push the best run below the fold.
const expanded = ref(false);

const collapsed = computed(() => mobile.value && !expanded.value);

const { modelSlug, budget, starSystem, commodity, priceAge, update } =
  useTradeRouteRun();

const { data: starSystems } = useTradeRouteStarSystemsFilters();
const { data: commodities } = useTradeRouteCommoditiesFilters();

const budgetInput = ref(budget.value ? String(budget.value) : "");

watch(budget, (value) => {
  budgetInput.value = value ? String(value) : "";
});

// Typed rather than picked, so the URL follows once the pilot pauses instead
// of on every keystroke.
const pushBudget = debounce(async (value: string) => {
  const amount = Number(value.replace(/[^\d]/g, ""));

  await update({ budget: amount > 0 ? String(amount) : undefined });
}, 400);

watch(budgetInput, (value) => {
  void pushBudget(value);
});

const commodityValue = computed({
  get: () => commodity.value,
  set: (value?: string) => {
    // The buyers of one purchase are a view of one commodity: picking another
    // leaves that view rather than asking the old terminal for the new cargo.
    void update({ commodity: value || undefined, origin: undefined });
  },
});

const summaryChips = computed(() => [
  starSystem.value ?? t("labels.tradeRoutes.anySystem"),
  priceAges.value.find((option) => option.value === priceAge.value)?.label,
  commodities.value?.find((option) => option.value === commodity.value)
    ?.label ?? t("labels.tradeRoutes.allCommodities"),
]);

const priceAges = computed(() => [
  {
    value: TradeRoutePriceAgesEnum.DAY,
    label: t("labels.tradeRoutes.priceAges.day"),
  },
  {
    value: TradeRoutePriceAgesEnum.THREE_DAYS,
    label: t("labels.tradeRoutes.priceAges.threeDays"),
  },
  {
    value: TradeRoutePriceAgesEnum.ANY,
    label: t("labels.tradeRoutes.priceAges.any"),
  },
]);
</script>

<template>
  <section class="run-bar" :aria-label="t('labels.tradeRoutes.yourRun')">
    <div v-if="collapsed" class="run-bar__summary">
      <div class="run-bar__summary-head">
        <div class="run-bar__ship-text">
          <span class="run-bar__ship-name">
            {{ ship?.name ?? t("labels.tradeRoutes.noShipShort") }}
          </span>
          <span class="run-bar__hint">
            <template v-if="ship?.metrics.cargo">
              {{ t("labels.tradeRoutes.scu", { count: ship.metrics.cargo }) }}
            </template>
            <template v-if="budget">
              · {{ toNumber(budget, "integer") }} aUEC
            </template>
          </span>
        </div>
        <Btn
          :aria-expanded="false"
          aria-controls="trade-routes-run-controls"
          @click="expanded = true"
        >
          {{ t("actions.tradeRoutes.editRun") }}
        </Btn>
      </div>
      <div class="run-bar__chips">
        <span v-for="chip in summaryChips" :key="chip" class="run-bar__chip">
          {{ chip }}
        </span>
      </div>
    </div>

    <div v-else id="trade-routes-run-controls">
      <div class="run-bar__row run-bar__row--bring">
        <div class="run-bar__cell run-bar__ship">
          <img
            v-if="ship?.media.storeImage?.smallUrl"
            class="run-bar__ship-image"
            :src="ship.media.storeImage.smallUrl"
            alt=""
          />
          <div class="run-bar__ship-text">
            <span class="run-bar__label">{{
              t("labels.tradeRoutes.ship")
            }}</span>
            <template v-if="ship">
              <router-link
                class="run-bar__ship-name"
                :to="{ name: 'ship', params: { slug: ship.slug } }"
              >
                {{ ship.name }}
              </router-link>
              <span v-if="ship.metrics.cargo" class="run-bar__hint">
                {{ t("labels.tradeRoutes.scu", { count: ship.metrics.cargo }) }}
              </span>
            </template>
            <span v-else class="run-bar__hint">
              {{ t("labels.tradeRoutes.noShip") }}
            </span>
          </div>
          <Btn class="run-bar__ship-action" @click="emit('pick-ship')">
            {{
              modelSlug
                ? t("actions.tradeRoutes.changeShip")
                : t("actions.tradeRoutes.pickShip")
            }}
          </Btn>
        </div>

        <div class="run-bar__cell">
          <label class="run-bar__label" for="trade-routes-budget">
            {{ t("labels.tradeRoutes.budget") }}
          </label>
          <div class="run-bar__budget" :class="{ 'is-disabled': !modelSlug }">
            <input
              id="trade-routes-budget"
              v-model="budgetInput"
              inputmode="numeric"
              :placeholder="t('labels.tradeRoutes.budgetPlaceholder')"
              :disabled="!modelSlug"
            />
            <span class="run-bar__unit">aUEC</span>
          </div>
          <span v-if="budget" class="run-bar__hint">
            {{ toNumber(budget, "integer") }} aUEC
          </span>
        </div>
      </div>

      <div class="run-bar__row run-bar__row--trade">
        <div class="run-bar__cell">
          <span class="run-bar__label">{{
            t("labels.tradeRoutes.buyIn")
          }}</span>
          <BtnGroup segmented block>
            <Btn :active="!starSystem" @click="update({ system: undefined })">
              {{ t("labels.tradeRoutes.anySystem") }}
            </Btn>
            <Btn
              v-for="option in starSystems ?? []"
              :key="String(option.value)"
              :active="starSystem === option.value"
              @click="update({ system: String(option.value) })"
            >
              {{ option.label }}
            </Btn>
          </BtnGroup>
        </div>

        <div class="run-bar__cell">
          <span class="run-bar__label">{{
            t("labels.tradeRoutes.commodity")
          }}</span>
          <BaseSelect
            v-model="commodityValue"
            name="commodity"
            :options="commodities ?? []"
            :label="t('labels.tradeRoutes.allCommodities')"
            :no-label="true"
            searchable
            clearable
          />
        </div>

        <div class="run-bar__cell">
          <span class="run-bar__label">{{
            t("labels.tradeRoutes.priceAge")
          }}</span>
          <BtnGroup segmented block>
            <Btn
              v-for="option in priceAges"
              :key="option.value"
              :active="priceAge === option.value"
              @click="
                update({
                  priceAge:
                    option.value === TradeRoutePriceAgesEnum.THREE_DAYS
                      ? undefined
                      : option.value,
                })
              "
            >
              {{ option.label }}
            </Btn>
          </BtnGroup>
        </div>
      </div>
      <div v-if="mobile" class="run-bar__done">
        <Btn block @click="expanded = false">
          {{ t("actions.tradeRoutes.doneEditing") }}
        </Btn>
      </div>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.run-bar {
  display: flex;
  flex-direction: column;
  border: 1px solid $gray-dark;
  border-radius: 10px;
  background: $panel-bg;
}

.run-bar__row {
  display: grid;
  gap: 0;
}

.run-bar__row--bring {
  grid-template-columns: minmax(0, 1.6fr) minmax(0, 1fr);
  border-bottom: 1px solid $gray-dark;
}

.run-bar__row--trade {
  grid-template-columns: minmax(0, 1.3fr) minmax(0, 1fr) minmax(0, 1fr);
}

// Top-aligned: the select and the segmented groups differ by a few pixels in
// height, and centring them left the labels on different lines.
.run-bar__cell {
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  gap: 6px;
  min-width: 0;
  padding: 18px 24px;

  & + & {
    border-left: 1px solid $gray-dark;
  }
}

.run-bar__ship {
  flex-direction: row;
  align-items: center;
  align-self: center;
  gap: 20px;
}

.run-bar__ship-image {
  width: 120px;
  height: 64px;
  flex-shrink: 0;
  border-radius: 6px;
  object-fit: cover;
}

.run-bar__ship-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.run-bar__ship-name {
  color: #fff;
  font-size: 1.25rem;
  font-weight: 700;
}

.run-bar__ship-action {
  margin-left: auto;
}

.run-bar__label {
  color: var(--color-text-dim, #959595);
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.run-bar__hint {
  color: var(--color-text-dim, #959595);
  font-size: 0.85rem;
}

.run-bar__budget {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 44px;
  padding: 0 12px;
  border: 1px solid $gray-dark;
  border-radius: 6px;
  background: $gray-black;

  input {
    flex-grow: 1;
    min-width: 0;
    border: 0;
    background: transparent;
    color: #fff;
    font-size: 1rem;
    font-weight: 600;
    outline: none;
  }

  &:focus-within {
    border-color: var(--color-primary, #428bca);
  }

  &.is-disabled {
    opacity: 0.5;
  }
}

.run-bar__unit {
  color: var(--color-text-dim, #959595);
  font-size: 0.85rem;
}

.run-bar__summary {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 14px 16px;
}

.run-bar__summary-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.run-bar__chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.run-bar__chip {
  padding: 4px 12px;
  border: 1px solid $gray-dark;
  border-radius: 999px;
  background: $gray-black;
  font-size: 0.85rem;
}

.run-bar__done {
  padding: 14px 16px;
  border-top: 1px solid $gray-dark;
}

@media (max-width: $desktop-breakpoint) {
  .run-bar__row--bring,
  .run-bar__row--trade {
    grid-template-columns: minmax(0, 1fr);
  }

  .run-bar__cell {
    padding: 14px 16px;

    & + & {
      border-top: 1px solid $gray-dark;
      border-left: 0;
    }
  }

  .run-bar__ship-image {
    width: 72px;
    height: 44px;
  }
}
</style>
