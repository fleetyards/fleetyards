<script lang="ts">
export default {
  name: "HangarPlannerCostTiles",
};
</script>

<script lang="ts" setup>
import StatsPanel from "@/shared/components/StatsPanel/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useI18n } from "@/shared/composables/useI18n";
import type { HangarPlanTotals } from "@/services/fyApi";

type Props = {
  totals: HangarPlanTotals;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { amount, range } = usePlanMoney();

// Credits are subtracted from the spend, so they read as negative amounts.
const credit = (value: number) => (value ? `−${amount(value)}` : amount(0));

const tiles = computed(() => [
  {
    key: "spend",
    icon: "fa-duotone fa-cart-shopping",
    value: amount(props.totals.routedSpend),
    note:
      props.totals.maxSpend !== props.totals.routedSpend
        ? t("hangarPlanner.summary.upTo", {
            value: amount(props.totals.maxSpend),
          })
        : undefined,
  },
  {
    key: "meltCredit",
    icon: "fa-duotone fa-fire",
    value: credit(props.totals.meltCredit),
  },
  {
    key: "startingCredit",
    icon: "fa-duotone fa-wallet",
    value: credit(props.totals.startingCredit),
  },
  {
    key: "cashNeeded",
    icon: "fa-duotone fa-money-bill",
    value: range(props.totals.cashNeededMin, props.totals.cashNeededMax),
  },
]);
</script>

<template>
  <div class="plan-cost-tiles" data-test="hangar-plan-cost-tiles">
    <StatsPanel
      v-for="tile in tiles"
      :key="tile.key"
      :label="t(`hangarPlanner.summary.${tile.key}`)"
      :icon="tile.icon"
      :outer-spacing="false"
    >
      <template #value>
        <span :data-test="`hangar-plan-tile-${tile.key}`">
          {{ tile.value }}
          <small v-if="tile.note" class="plan-cost-tiles__note">
            {{ tile.note }}
          </small>
        </span>
      </template>
    </StatsPanel>
  </div>
</template>

<style lang="scss" scoped>
.plan-cost-tiles__note {
  display: block;
  margin-top: 6px;
  font-size: 0.8rem;
  font-weight: 400;
  color: var(--color-text-dim);
}

.plan-cost-tiles {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-bottom: 16px;

  @media (max-width: 991px) {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  @media (max-width: 575px) {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
