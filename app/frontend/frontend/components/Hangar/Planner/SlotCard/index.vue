<script lang="ts">
export default {
  name: "HangarPlannerSlotCard",
};
</script>

<script lang="ts" setup>
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import RouteChain from "@/frontend/components/Hangar/Planner/RouteChain/index.vue";
import { useAcquisitionNodes } from "@/frontend/components/Hangar/Planner/RouteChain/types";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useCandidateSpecs } from "@/frontend/components/Hangar/Planner/candidateSpecs";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type HangarPlanAcquisition,
  type HangarPlanSlot,
  type HangarPlanSlotCost,
  HangarPlanSlotStateEnum,
} from "@/services/fyApi";

type Props = {
  slot: HangarPlanSlot;
  cost?: HangarPlanSlotCost;
};

const props = withDefaults(defineProps<Props>(), {
  cost: undefined,
});

const { t } = useI18n();
const { money, range, startRange } = usePlanMoney();
const acquisitionNodes = useAcquisitionNodes();

const stateVariant = computed(() => {
  switch (props.slot.state) {
    case HangarPlanSlotStateEnum.DECIDED:
      return PillVariantsEnum.SUCCESS;
    case HangarPlanSlotStateEnum.UNDECIDED:
      return PillVariantsEnum.WARNING;
    default:
      return PillVariantsEnum.NEUTRAL;
  }
});

const filterChips = computed(() => {
  const filters = props.slot.filters;
  const chips: string[] = [
    ...(filters.classificationIn ?? []),
    ...(filters.focusIn ?? []),
    ...(filters.sizeIn ?? []),
    ...(filters.manufacturerIn ?? []),
    ...(filters.productionStatusIn ?? []),
  ].map((value) => value.replace(/[-_]/g, " "));

  if (filters.pledgePriceGteq !== undefined) {
    chips.push(
      t("hangarPlanner.filterChips.priceFrom", {
        price: money(filters.pledgePriceGteq),
      }),
    );
  }
  if (filters.pledgePriceLteq !== undefined) {
    chips.push(
      t("hangarPlanner.filterChips.priceTo", {
        price: money(filters.pledgePriceLteq),
      }),
    );
  }
  if (filters.cargoGteq !== undefined) {
    chips.push(
      t("hangarPlanner.filterChips.cargo", { cargo: filters.cargoGteq }),
    );
  }
  if (filters.onSaleEq) chips.push(t("hangarPlanner.filterChips.onSale"));

  return chips;
});

// A slot whose units all lack a start has spent nothing yet, so its store price
// says more than a counted $0.00.
const countedCost = computed(() => {
  const { cost, slot } = props;
  if (!cost || slot.state === HangarPlanSlotStateEnum.OPEN) return undefined;
  if (cost.storeCost !== 0 && cost.maxCost === 0) return undefined;

  return range(cost.minCost, cost.maxCost);
});

const uncountedCost = computed(() => {
  const { cost } = props;
  if (!cost || cost.storeCost === 0) return undefined;

  return [
    `${countedCost.value ? "+ " : ""}${startRange(cost.storeCostMin, cost.storeCost)}`,
    t("hangarPlanner.comparison.flow.onlyInMax"),
  ].join(" · ");
});

const decided = computed(
  () => props.slot.state === HangarPlanSlotStateEnum.DECIDED,
);

const decidedCandidate = computed(() =>
  decided.value ? props.slot.candidates[0] : undefined,
);

const unresolved = computed(() =>
  decidedCandidate.value
    ? Number(
        !decidedCandidate.value.acquisitions.some(
          (acquisition) => acquisition.routeComplete,
        ),
      )
    : 0,
);

const undecided = computed(
  () => props.slot.state === HangarPlanSlotStateEnum.UNDECIDED,
);

const { specs } = useCandidateSpecs(() => props.slot.candidates);

const routeCost = (acquisition: HangarPlanAcquisition) => {
  const prices = [
    acquisition.price,
    ...acquisition.steps.map((step) => step.price),
  ];
  if (prices.some((price) => price === null || price === undefined)) {
    return undefined;
  }
  return prices.reduce<number>((sum, price) => sum + (price ?? 0), 0);
};
</script>

<template>
  <Panel
    :id="`hangar-plan-slot-${slot.id}`"
    :variant="PanelVariantsEnum.SLIM"
    class="plan-slot"
    tabindex="-1"
    :data-test="`hangar-plan-slot-${slot.id}`"
  >
    <PanelHeading compact divider>
      {{ slot.label }}
      <template #subtitle>
        <Pill :variant="stateVariant" data-test="hangar-plan-slot-state">
          {{ t(`hangarPlanner.states.${slot.state}`) }}
        </Pill>
        <span v-if="countedCost" class="plan-slot__cost">
          {{ countedCost }}
        </span>
        <span
          v-if="uncountedCost"
          class="plan-slot__meta"
          data-test="hangar-plan-slot-store-cost"
        >
          {{ uncountedCost }}
        </span>
      </template>
    </PanelHeading>
    <PanelBody class="plan-slot__body">
      <p v-if="slot.description" class="plan-slot__description">
        {{ slot.description }}
      </p>
      <ul
        v-if="filterChips.length"
        class="plan-slot__filters"
        :aria-label="t('hangarPlanner.fields.filters')"
      >
        <li v-for="chip in filterChips" :key="chip">
          <Pill :variant="PillVariantsEnum.NEUTRAL">{{ chip }}</Pill>
        </li>
      </ul>

      <div
        v-if="slot.state === HangarPlanSlotStateEnum.OPEN"
        class="plan-slot__empty"
      >
        <i class="fa-light fa-circle-dashed" aria-hidden="true" />
        <p class="plan-slot__hint">{{ t("hangarPlanner.openSlotHint") }}</p>
      </div>

      <ul
        v-else
        class="plan-slot__candidates"
        :class="{ 'plan-slot__candidates--versus': undecided }"
      >
        <li
          v-for="candidate in slot.candidates"
          :key="candidate.id"
          class="plan-slot__candidate"
        >
          <img
            :src="candidate.model.image?.smallUrl || fallbackImage"
            :alt="candidate.model.name"
            class="plan-slot__image"
            loading="lazy"
          />
          <div class="plan-slot__candidate-body">
            <div class="plan-slot__candidate-title">
              <strong><ShipName :ship="candidate.model" /></strong>
              <span
                v-if="candidate.model.manufacturerName"
                class="plan-slot__meta"
              >
                {{ candidate.model.manufacturerName }}
              </span>
            </div>
            <dl class="plan-slot__specs">
              <div
                v-for="spec in specs(candidate)"
                :key="spec.key"
                class="plan-slot__spec"
              >
                <dt>{{ t(`hangarPlanner.specs.${spec.key}`) }}</dt>
                <dd>
                  {{ spec.value }}
                  <span
                    v-if="undecided && spec.best"
                    class="plan-slot__best"
                    data-test="hangar-plan-candidate-best"
                  >
                    {{ t("hangarPlanner.specs.best") }}
                  </span>
                </dd>
              </div>
            </dl>
            <span class="plan-slot__meta">
              <template v-if="candidate.paintName">
                {{ candidate.paintName }} ·
              </template>
              <template v-if="candidate.ownedCount">
                {{
                  t("hangarPlanner.ownedCount", {
                    count: candidate.ownedCount,
                  })
                }}
                ·
              </template>
              <template v-if="!candidate.model.onSale">
                {{ t("hangarPlanner.notOnSale") }}
              </template>
              <span
                v-if="!candidate.matchesFilters"
                class="plan-slot__warning"
                data-test="hangar-plan-candidate-mismatch"
              >
                {{ t("hangarPlanner.outsideFilters") }}
              </span>
            </span>
          </div>
        </li>
      </ul>

      <section v-if="decidedCandidate" class="plan-slot__routes">
        <h4>{{ t("hangarPlanner.routes") }}</h4>
        <div
          v-for="acquisition in decidedCandidate.acquisitions"
          :key="acquisition.id"
          class="plan-slot__route"
          data-test="hangar-plan-route"
        >
          <RouteChain :nodes="acquisitionNodes(acquisition)" />
          <div class="plan-slot__route-cost-cell">
            <span
              v-if="!acquisition.routeComplete"
              class="plan-slot__route-cost plan-slot__route-cost--missing"
            >
              {{ t("hangarPlanner.vehicleStatuses.unrouted") }}
            </span>
            <span v-else class="plan-slot__route-cost">
              {{ money(routeCost(acquisition)) }}
            </span>
          </div>
        </div>
        <div v-if="unresolved > 0" class="plan-slot__gap">
          <span>
            <i class="fa-light fa-route" aria-hidden="true" />
            {{ t("hangarPlanner.unresolvedUnits", { count: unresolved }) }}
          </span>
        </div>
      </section>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.plan-slot {
  scroll-margin-top: 16px;

  &:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
  }
}

.plan-slot__hint,
.plan-slot__meta {
  color: var(--color-text-dim);
}

.plan-slot__cost {
  font-weight: 600;
  color: var(--color-lifted);
}

.plan-slot__body {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.plan-slot__description,
.plan-slot__hint {
  margin: 0;
}

.plan-slot__filters,
.plan-slot__candidates {
  margin: 0;
  padding: 0;
  list-style: none;
}

.plan-slot__filters {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.plan-slot__empty {
  display: flex;
  flex-direction: column;
  gap: 10px;
  align-items: center;
  padding: 24px 16px;
  text-align: center;
  border: 1px dashed var(--color-edge);
  border-radius: 12px;

  > i {
    font-size: 1.4rem;
    color: var(--color-muted);
  }
}

.plan-slot__candidates {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.plan-slot__candidate {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-items: center;
}

.plan-slot__image {
  width: 160px;
  height: 90px;
  object-fit: cover;
  border: 1px solid var(--color-edge-soft);
  border-radius: 8px;
}

.plan-slot__candidate-body {
  display: flex;
  flex: 1 1 220px;
  flex-direction: column;
  gap: 8px;
  min-width: 0;
}

.plan-slot__candidate-title {
  display: flex;
  flex-direction: column;

  strong {
    font-size: 1rem;
    color: var(--color-lifted);
  }
}

.plan-slot__specs {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 20px;
  margin: 0;
}

.plan-slot__spec {
  display: flex;
  flex-direction: column;
  gap: 2px;

  dt {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.625rem;
    font-weight: 400;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    font-size: 0.84375rem;
    font-weight: 600;
    color: var(--color-lifted);
  }
}

.plan-slot__best {
  margin-left: 4px;
  font-size: 0.75rem;
  color: var(--color-success);
}

// Undecided ships stand side by side so the trade-off reads across.
.plan-slot__candidates--versus {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));

  .plan-slot__candidate {
    flex-direction: column;
    align-items: stretch;
    padding: 12px;
    border: 1px solid var(--color-edge-soft);
    border-radius: 12px;
    background: var(--color-control);
  }

  .plan-slot__image {
    width: 100%;
    height: 120px;
  }

  .plan-slot__candidate-body {
    flex: 1 1 auto;
  }

  .plan-slot__specs {
    flex-direction: column;
    gap: 0;
  }

  .plan-slot__spec {
    flex-direction: row;
    justify-content: space-between;
    padding: 6px 0;
    border-top: 1px solid var(--color-edge-faint);
  }
}

.plan-slot__routes {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px;
  border: 1px solid var(--color-edge-faint);
  border-radius: 12px;
  background: var(--color-gray-black);

  h4 {
    margin: 0;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 0.625rem;
    font-weight: 400;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }
}

.plan-slot__route {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;

  & + & {
    padding-top: 10px;
    border-top: 1px solid var(--color-edge-faint);
  }
}

.plan-slot__route-cost-cell {
  margin-left: auto;
  white-space: nowrap;
}

.plan-slot__route-cost {
  font-weight: 600;
  color: var(--color-lifted);
}

.plan-slot__route-cost--missing {
  color: var(--color-warning);
}

.plan-slot__warning {
  margin-left: 4px;
  color: var(--color-warning);
}

.plan-slot__gap {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border: 1px dashed var(--color-warning);
  border-radius: 8px;
  color: var(--color-warning);
}
</style>
