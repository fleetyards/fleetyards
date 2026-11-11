<script lang="ts">
export default {
  name: "HangarPlannerUpgradeNote",
};
</script>

<script lang="ts" setup>
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { ccuNote } from "@/frontend/components/Hangar/Planner/reach";
import { useI18n } from "@/shared/composables/useI18n";
import type { HangarPlanModel } from "@/services/fyApi";

type Props = {
  from: HangarPlanModel;
  to: HangarPlanModel;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { money } = usePlanMoney();

const cost = computed(() =>
  typeof props.from.pledgePrice === "number" &&
  typeof props.to.pledgePrice === "number"
    ? Math.max(props.to.pledgePrice - props.from.pledgePrice, 0)
    : undefined,
);

const note = computed(() => ccuNote(props.to));
</script>

<template>
  <section class="upgrade-note" data-test="ship-panel-upgrade">
    <h4 class="upgrade-note__label">{{ t("hangarPlanner.panel.upgrade") }}</h4>
    <p class="upgrade-note__line">
      <span>
        {{
          t("hangarPlanner.panel.upgradeLine", { from: from.name, to: to.name })
        }}
      </span>
      <strong>{{ money(cost) }}</strong>
    </p>
    <p v-if="note" class="upgrade-note__status upgrade-note__status--warning">
      <i class="fa-solid fa-circle" aria-hidden="true" />
      {{ t(note) }}
    </p>
    <p v-else class="upgrade-note__status">
      <i class="fa-solid fa-circle" aria-hidden="true" />
      {{ t("hangarPlanner.panel.ccuOnSale") }}
    </p>
  </section>
</template>

<style lang="scss" scoped>
.upgrade-note {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 10px 12px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
}

.upgrade-note__label {
  margin: 0;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 0.625rem;
  font-weight: 400;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.upgrade-note__line {
  display: flex;
  gap: 8px;
  justify-content: space-between;
  margin: 0;

  strong {
    color: var(--color-lifted);
  }
}

.upgrade-note__status {
  display: flex;
  gap: 6px;
  align-items: center;
  margin: 0;
  font-size: 0.8rem;
  color: var(--color-success);

  i {
    font-size: 0.45rem;
  }
}

.upgrade-note__status--warning {
  color: var(--color-warning);
}
</style>
