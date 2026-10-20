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
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
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

const chain = (acquisition: HangarPlanAcquisition) =>
  [acquisition.startModel, ...acquisition.steps.map((step) => step.toModel)]
    .map((model) => model.name)
    .join(" → ");

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
) => comlink.emit("open-modal", { component, props });

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
    :variant="PanelVariantsEnum.SLIM"
    class="plan-slot"
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
        <span v-if="cost && slot.state !== HangarPlanSlotStateEnum.OPEN">
          {{ range(cost.minCost, cost.maxCost) }}
        </span>
      </template>
      <template v-if="!readonly" #actions>
        <Btn
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
    <PanelBody>
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
      <p
        v-if="slot.state === HangarPlanSlotStateEnum.OPEN"
        class="plan-slot__hint"
      >
        {{ t("hangarPlanner.openSlotHint") }}
      </p>

      <ul class="plan-slot__candidates">
        <li
          v-for="candidate in slot.candidates"
          :key="candidate.id"
          class="plan-slot__candidate"
        >
          <img
            v-if="candidate.model.image?.smallUrl"
            :src="candidate.model.image.smallUrl"
            :alt="candidate.model.name"
            class="plan-slot__image"
            loading="lazy"
          />
          <div class="plan-slot__candidate-body">
            <strong>{{ candidate.model.name }}</strong>
            <span class="plan-slot__meta">
              {{ money(candidate.model.pledgePrice) }}
              <template v-if="candidate.paintName">
                · {{ candidate.paintName }}
              </template>
              <template v-if="candidate.ownedCount">
                ·
                {{
                  t("hangarPlanner.ownedCount", {
                    count: candidate.ownedCount,
                  })
                }}
              </template>
              <template v-if="!candidate.model.onSale">
                · {{ t("hangarPlanner.notOnSale") }}
              </template>
              <span
                v-if="!candidate.matchesFilters"
                class="plan-slot__warning"
                data-test="hangar-plan-candidate-mismatch"
              >
                · {{ t("hangarPlanner.outsideFilters") }}
              </span>
            </span>
          </div>
          <div v-if="!readonly" class="plan-slot__candidate-actions">
            <Btn
              v-if="slot.state === HangarPlanSlotStateEnum.UNDECIDED"
              :size="BtnSizesEnum.XS"
              data-test="hangar-plan-choose"
              @click="chooseCandidate(candidate)"
            >
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

      <div v-if="decidedCandidate" class="plan-slot__routes">
        <h4>{{ t("hangarPlanner.routes") }}</h4>
        <ul>
          <li
            v-for="acquisition in decidedCandidate.acquisitions"
            :key="acquisition.id"
            class="plan-slot__route"
            data-test="hangar-plan-route"
          >
            <div>
              <Pill :variant="PillVariantsEnum.NEUTRAL">
                {{ t(`hangarPlanner.startKinds.${acquisition.startKind}`) }}
              </Pill>
              {{ chain(acquisition) }}
              <span
                v-if="
                  acquisition.sourceMissing ||
                  acquisition.steps.some((step) => step.sourceMissing)
                "
                class="plan-slot__warning"
              >
                <i class="fa-duotone fa-triangle-exclamation" />
                {{ t("hangarPlanner.sourceMissing") }}
              </span>
            </div>
            <div class="plan-slot__route-actions">
              <span>{{ money(routeCost(acquisition)) }}</span>
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
          </li>
        </ul>
        <p v-if="unresolved > 0" class="plan-slot__gap">
          {{ t("hangarPlanner.unresolvedUnits", { count: unresolved }) }}
          <Btn
            v-if="!readonly"
            :size="BtnSizesEnum.XS"
            data-test="hangar-plan-add-route"
            @click="openRoute(decidedCandidate)"
          >
            <i class="fa-light fa-route" />
            {{ t("hangarPlanner.addRouteShort") }}
          </Btn>
        </p>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.plan-slot__quantity {
  color: var(--color-text-dim);
}

.plan-slot__hint,
.plan-slot__meta {
  color: var(--color-text-dim);
}

.plan-slot__description {
  margin: 0 0 8px;
}

.plan-slot__filters {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin: 0 0 8px;
  padding: 0;
  list-style: none;
}

.plan-slot__candidates,
.plan-slot__routes ul {
  margin: 0;
  padding: 0;
  list-style: none;
}

.plan-slot__candidate,
.plan-slot__route {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 8px 0;

  & + & {
    border-top: 1px solid var(--color-edge-faint);
  }
}

.plan-slot__image {
  width: 64px;
  height: 40px;
  object-fit: cover;
  border-radius: 4px;
}

.plan-slot__candidate-body {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;
}

.plan-slot__candidate-actions,
.plan-slot__route-actions {
  display: flex;
  gap: 4px;
  align-items: center;
  margin-left: auto;
  white-space: nowrap;
}

.plan-slot__routes h4 {
  margin: 12px 0 4px;
  font-size: 0.9rem;
  color: var(--color-text-dim);
}

.plan-slot__warning {
  margin-left: 8px;
  color: var(--color-warning);
}

.plan-slot__gap {
  display: flex;
  gap: 8px;
  align-items: center;
  margin: 8px 0 0;
  color: var(--color-warning);
}
</style>
