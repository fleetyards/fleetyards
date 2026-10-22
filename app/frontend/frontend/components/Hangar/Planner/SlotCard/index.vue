<script lang="ts">
export default {
  name: "HangarPlannerSlotCard",
};
</script>

<script lang="ts" setup>
import type { Component } from "vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import RouteChain from "@/frontend/components/Hangar/Planner/RouteChain/index.vue";
import { useAcquisitionNodes } from "@/frontend/components/Hangar/Planner/RouteChain/types";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanSlot,
  type HangarPlanSlotCost,
  HangarPlanSlotStateEnum,
  useChooseHangarPlanSlotCandidate,
  useDestroyHangarPlanAcquisition,
  useDestroyHangarPlanCandidate,
  useDestroyHangarPlanSlot,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot: HangarPlanSlot;
  cost?: HangarPlanSlotCost;
  readonly?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  cost: undefined,
  readonly: false,
});

const { t } = useI18n();
const { money, range } = usePlanMoney();
const acquisitionNodes = useAcquisitionNodes();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

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

const decided = computed(
  () => props.slot.state === HangarPlanSlotStateEnum.DECIDED,
);

const decidedCandidate = computed(() =>
  decided.value ? props.slot.candidates[0] : undefined,
);

const unresolved = computed(() =>
  decidedCandidate.value
    ? props.slot.quantity - decidedCandidate.value.acquisitions.length
    : 0,
);

const undecided = computed(
  () => props.slot.state === HangarPlanSlotStateEnum.UNDECIDED,
);

// Side by side, the figure that wins its row is marked so the trade-off reads
// without comparing every number by eye. One candidate has nothing to beat.
const best = computed(() => {
  const models = props.slot.candidates.map((candidate) => candidate.model);
  const prices = models
    .map((model) => model.pledgePrice)
    .filter((price): price is number => typeof price === "number");
  const cargos = models
    .map((model) => model.cargo)
    .filter((cargo): cargo is number => typeof cargo === "number" && cargo > 0);

  return {
    price: prices.length > 1 ? Math.min(...prices) : undefined,
    cargo: cargos.length > 1 ? Math.max(...cargos) : undefined,
  };
});

const specs = (candidate: HangarPlanCandidate) => {
  const model = candidate.model;

  return [
    {
      key: "price",
      value: money(model.pledgePrice),
      best:
        best.value.price !== undefined &&
        model.pledgePrice === best.value.price,
    },
    {
      key: "cargo",
      value: model.cargo ? `${model.cargo} SCU` : "–",
      best: best.value.cargo !== undefined && model.cargo === best.value.cargo,
    },
    { key: "crew", value: model.crew ?? "–", best: false },
    { key: "size", value: model.size ?? "–", best: false },
  ];
};

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

const openModal = (
  component: () => Promise<Component>,
  props: Record<string, unknown>,
  options: { wide?: boolean } = {},
) => comlink.emit("open-modal", { component, props, ...options });

const editSlot = () =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/SlotModal/index.vue"),
    { planId: props.planId, slot: props.slot },
  );

const addCandidates = () =>
  openModal(
    () =>
      import("@/frontend/components/Hangar/Planner/CandidatePickerModal/index.vue"),
    { planId: props.planId, slot: props.slot },
  );

const openRoute = (
  candidate: HangarPlanCandidate,
  acquisition?: HangarPlanAcquisition,
) =>
  openModal(
    () => import("@/frontend/components/Hangar/Planner/RouteModal/index.vue"),
    { planId: props.planId, candidate, acquisition },
    { wide: true },
  );

const destroySlot = useDestroyHangarPlanSlot();
const destroyCandidate = useDestroyHangarPlanCandidate();
const destroyAcquisition = useDestroyHangarPlanAcquisition();
const choose = useChooseHangarPlanSlotCandidate();

const run = async (request: Promise<Parameters<typeof updatePlan>[0]>) => {
  try {
    updatePlan(await request);
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  }
};

const removeSlot = () =>
  run(
    destroySlot.mutateAsync({ hangarPlanId: props.planId, id: props.slot.id }),
  );

const removeCandidate = (candidate: HangarPlanCandidate) =>
  run(
    destroyCandidate.mutateAsync({
      hangarPlanId: props.planId,
      id: candidate.id,
    }),
  );

const chooseCandidate = (candidate: HangarPlanCandidate) =>
  run(
    choose.mutateAsync({
      hangarPlanId: props.planId,
      id: props.slot.id,
      data: { candidateId: candidate.id },
    }),
  );

const removeRoute = (acquisition: HangarPlanAcquisition) =>
  run(
    destroyAcquisition.mutateAsync({
      hangarPlanId: props.planId,
      id: acquisition.id,
    }),
  );
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
      <span v-if="slot.quantity > 1" class="plan-slot__quantity">
        × {{ slot.quantity }}
      </span>
      <template #subtitle>
        <Pill :variant="stateVariant" data-test="hangar-plan-slot-state">
          {{ t(`hangarPlanner.states.${slot.state}`) }}
        </Pill>
        <span
          v-if="cost && slot.state !== HangarPlanSlotStateEnum.OPEN"
          class="plan-slot__cost"
        >
          {{ range(cost.minCost, cost.maxCost) }}
        </span>
      </template>
      <template v-if="!readonly" #actions>
        <Btn
          v-if="slot.state !== HangarPlanSlotStateEnum.OPEN"
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.GHOST"
          data-test="hangar-plan-slot-add-candidates"
          @click="addCandidates"
        >
          <i class="fa-light fa-plus" />
          {{ t("hangarPlanner.addShips") }}
        </Btn>
        <Btn
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          :aria-label="t('hangarPlanner.editSlot')"
          @click="editSlot"
        >
          <i class="fa-light fa-pen" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.XS"
          :variant="BtnVariantsEnum.BARE"
          :tone="BtnTonesEnum.DANGER"
          :aria-label="t('hangarPlanner.removeSlot')"
          :confirm="t('hangarPlanner.confirmRemoveSlot')"
          @click="removeSlot"
        >
          <i class="fa-light fa-trash" />
        </Btn>
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
        <Btn
          v-if="!readonly"
          :size="BtnSizesEnum.SM"
          data-test="hangar-plan-slot-add-candidates"
          @click="addCandidates"
        >
          <i class="fa-light fa-plus" />
          {{ t("hangarPlanner.addShips") }}
        </Btn>
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
              <strong>{{ candidate.model.name }}</strong>
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
          <div v-if="!readonly" class="plan-slot__candidate-actions">
            <Btn
              v-if="undecided"
              :size="BtnSizesEnum.MD"
              class="plan-slot__choose"
              data-test="hangar-plan-choose"
              @click="chooseCandidate(candidate)"
            >
              <i class="fa-light fa-check" />
              {{ t("hangarPlanner.choose") }}
            </Btn>
            <Btn
              :size="BtnSizesEnum.XS"
              :variant="BtnVariantsEnum.BARE"
              :tone="BtnTonesEnum.DANGER"
              :aria-label="t('hangarPlanner.removeCandidate')"
              @click="removeCandidate(candidate)"
            >
              <i class="fa-light fa-xmark" />
            </Btn>
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
          <div class="plan-slot__route-actions">
            <span class="plan-slot__route-cost">
              {{ money(routeCost(acquisition)) }}
            </span>
            <template v-if="!readonly">
              <Btn
                :size="BtnSizesEnum.XS"
                :variant="BtnVariantsEnum.BARE"
                :aria-label="
                  t('hangarPlanner.editRoute', {
                    ship: decidedCandidate.model.name,
                  })
                "
                @click="openRoute(decidedCandidate, acquisition)"
              >
                <i class="fa-light fa-pen" />
              </Btn>
              <Btn
                :size="BtnSizesEnum.XS"
                :variant="BtnVariantsEnum.BARE"
                :tone="BtnTonesEnum.DANGER"
                :aria-label="t('hangarPlanner.removeRoute')"
                @click="removeRoute(acquisition)"
              >
                <i class="fa-light fa-trash" />
              </Btn>
            </template>
          </div>
        </div>
        <div v-if="unresolved > 0" class="plan-slot__gap">
          <span>
            <i class="fa-light fa-route" aria-hidden="true" />
            {{ t("hangarPlanner.unresolvedUnits", { count: unresolved }) }}
          </span>
          <Btn
            v-if="!readonly"
            :size="BtnSizesEnum.XS"
            data-test="hangar-plan-add-route"
            @click="openRoute(decidedCandidate)"
          >
            <i class="fa-light fa-route" />
            {{ t("hangarPlanner.addRouteShort") }}
          </Btn>
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

.plan-slot__quantity,
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
    font-size: 10px;
    font-weight: 400;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    font-size: 13.5px;
    font-weight: 600;
    color: var(--color-lifted);
  }
}

.plan-slot__best {
  margin-left: 4px;
  font-size: 0.75rem;
  color: var(--color-success);
}

.plan-slot__candidate-actions,
.plan-slot__route-actions {
  display: flex;
  gap: 4px;
  align-items: center;
  margin-left: auto;
  white-space: nowrap;
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

  .plan-slot__candidate-actions {
    justify-content: space-between;
    margin-top: auto;
    margin-left: 0;
  }

  // Picking one is what an undecided slot is waiting for, so the button takes
  // the card's width rather than sitting small beside the remove icon.
  .plan-slot__choose {
    flex: 1;
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
    font-size: 10px;
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

.plan-slot__route-cost {
  font-weight: 600;
  color: var(--color-lifted);
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
