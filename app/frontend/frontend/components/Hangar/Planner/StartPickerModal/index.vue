<script lang="ts">
export default {
  name: "HangarPlannerStartPickerModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import PickList, {
  type PickListItem,
} from "@/frontend/components/Hangar/Planner/PickList/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { reaches } from "@/frontend/components/Hangar/Planner/reach";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type HangarPlanStart,
  useHangarPlanPairing,
} from "@/frontend/composables/useHangarPlanPairing";
import {
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanModel,
  type HangarPlanSlot,
  HangarPlanVehicleStatusEnum,
  useHangarPlan,
  useHangarPlanComparison,
  useHangarPlanResources,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot: HangarPlanSlot;
  // The ship the start leads to; unset for a slot still choosing its ship,
  // which is then picked after the start.
  candidate?: HangarPlanCandidate;
  acquisition?: HangarPlanAcquisition;
};

const props = withDefaults(defineProps<Props>(), {
  candidate: undefined,
  acquisition: undefined,
});

const STORE = "store";

// What a hangar ship free for a start can be in the plan so far.
const FILTERS = [
  HangarPlanVehicleStatusEnum.CHANGE,
  HangarPlanVehicleStatusEnum.PENDING,
  HangarPlanVehicleStatusEnum.UNASSIGNED,
  HangarPlanVehicleStatusEnum.KEPT,
];

const { t } = useI18n();
const { money } = usePlanMoney();
const comlink = useComlink();

const { data: plan } = useHangarPlan(() => props.planId);
const { data: comparison } = useHangarPlanComparison(() => props.planId);
const { data: resources, isLoading } = useHangarPlanResources(
  () => props.planId,
);

const { pairing, pairStart, pairEnd, decide } = useHangarPlanPairing(
  () => props.planId,
  plan,
);

const target = computed(() => props.candidate?.model);

// A slot still choosing its ship is reached from below its cheapest one, or
// from one of its ships already held.
const reachesSlot = (from: HangarPlanModel) => {
  const ships = props.slot.candidates.map((candidate) => candidate.model);
  if (ships.some((ship) => ship.id === from.id)) return true;

  const prices = ships
    .filter((ship) => ship.upgradable)
    .map((ship) => ship.pledgePrice)
    .filter((price): price is number => typeof price === "number");
  if (!prices.length) return false;

  return (
    from.upgradable &&
    (typeof from.pledgePrice !== "number" ||
      from.pledgePrice < Math.min(...prices))
  );
};

const statusOf = (vehicleId: string) =>
  comparison.value?.vehicles.find((entry) => entry.vehicleId === vehicleId)
    ?.status;

const freeVehicles = computed(() =>
  (resources.value?.vehicles ?? []).filter(
    (vehicle) =>
      (!vehicle.usedBy || vehicle.id === props.acquisition?.sourceVehicleId) &&
      (target.value
        ? reaches(vehicle.model, target.value)
        : reachesSlot(vehicle.model)),
  ),
);

const filters = ref<HangarPlanVehicleStatusEnum[]>([]);

const toggleFilter = (status: HangarPlanVehicleStatusEnum) => {
  filters.value = filters.value.includes(status)
    ? filters.value.filter((entry) => entry !== status)
    : [...filters.value, status];
};

const filterCount = (status: HangarPlanVehicleStatusEnum) =>
  freeVehicles.value.filter((vehicle) => statusOf(vehicle.id) === status)
    .length;

const shownFilters = computed(() =>
  FILTERS.filter((status) => filterCount(status) > 0),
);

const filtered = computed(() =>
  filters.value.length
    ? freeVehicles.value.filter((vehicle) =>
        filters.value.includes(
          statusOf(vehicle.id) as HangarPlanVehicleStatusEnum,
        ),
      )
    : freeVehicles.value,
);

const startItems = computed<PickListItem[]>(() => [
  ...(filters.value.length
    ? []
    : [
        {
          id: STORE,
          title: t("hangarPlanner.pick.buyNew"),
          meta: target.value?.name ?? t("hangarPlanner.pick.buyChosen"),
          price: target.value ? money(target.value.pledgePrice) : undefined,
          sortPrice: target.value?.pledgePrice,
          pinned: true,
        },
      ]),
  ...filtered.value.map((vehicle) => {
    const status = statusOf(vehicle.id);

    return {
      id: vehicle.id,
      title: vehicle.name || vehicle.model.name,
      meta: [
        vehicle.name ? vehicle.model.name : vehicle.model.manufacturerName,
        status ? t(`hangarPlanner.vehicleStatuses.${status}`) : undefined,
      ]
        .filter(Boolean)
        .join(" · "),
      price: money(vehicle.model.pledgePrice),
      sortPrice: vehicle.model.pledgePrice,
      badge:
        vehicle.id === props.acquisition?.sourceVehicleId
          ? t("hangarPlanner.pick.current")
          : vehicle.model.id === target.value?.id
            ? t("hangarPlanner.route.isTarget")
            : undefined,
      pinned: !!target.value && vehicle.model.id === target.value.id,
    };
  }),
]);

// A slot still choosing its ship is asked for the ship once the start is
// known, so only the ships that start can become are offered.
const start = ref<HangarPlanStart>();

const startModel = computed(() =>
  start.value?.kind === "owned"
    ? resources.value?.vehicles.find(
        (vehicle) =>
          start.value?.kind === "owned" && vehicle.id === start.value.vehicleId,
      )?.model
    : undefined,
);

const endItems = computed<PickListItem[]>(() =>
  props.slot.candidates
    .filter(
      (candidate) =>
        !startModel.value || reaches(startModel.value, candidate.model),
    )
    .map((candidate) => ({
      id: candidate.id,
      title: candidate.model.name,
      meta: candidate.model.manufacturerName ?? undefined,
      price: money(candidate.model.pledgePrice),
      sortPrice: candidate.model.pledgePrice,
      badge:
        candidate.model.id === startModel.value?.id
          ? t("hangarPlanner.pick.sameModel")
          : undefined,
      pinned: candidate.model.id === startModel.value?.id,
    })),
);

const close = () => comlink.emit("close-modal", true);

const chooseStart = async (item: PickListItem) => {
  const picked: HangarPlanStart =
    item.id === STORE
      ? { kind: "store" }
      : { kind: "owned", vehicleId: item.id };

  if (!props.candidate) {
    start.value = picked;
    return;
  }

  if (await pairStart(props.candidate, picked, props.acquisition)) close();
};

const chooseEnd = async (item: PickListItem) => {
  const candidate = props.slot.candidates.find((entry) => entry.id === item.id);
  if (!candidate || !start.value) return;

  if (
    (await decide(props.slot, candidate)) &&
    (await pairStart(candidate, start.value))
  ) {
    close();
  }
};

const remove = async () => {
  if (await pairEnd({ kind: "remove" }, { acquisition: props.acquisition })) {
    close();
  }
};

// Buy-backs, in-game purchases and store starts on another ship are planned
// with the route itself.
const otherStarts = () =>
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Hangar/Planner/RouteModal/index.vue"),
    props: {
      planId: props.planId,
      candidate: props.candidate,
      acquisition: props.acquisition,
    },
    wide: true,
  });
</script>

<template>
  <Modal
    :title="
      t('hangarPlanner.pick.startTitle', { ship: target?.name ?? slot.label })
    "
    :eyebrow="t('hangarPlanner.pick.startEyebrow')"
  >
    <template v-if="start">
      <p class="start-picker__hint">
        {{ t("hangarPlanner.pick.chooseEnd") }}
      </p>
      <PickList
        name="hangar-plan-start-end"
        :items="endItems"
        :action-label="t('hangarPlanner.pick.use')"
        :empty="t('hangarPlanner.pick.noReachableShip')"
        data-test="hangar-plan-start-end-picker"
        @pick="chooseEnd"
      />
    </template>
    <PickList
      v-else
      name="hangar-plan-start"
      :items="startItems"
      :loading="isLoading"
      :action-label="t('hangarPlanner.pick.use')"
      :empty="t('hangarPlanner.pick.noShips')"
      data-test="hangar-plan-start-picker"
      @pick="chooseStart"
    >
      <template v-if="shownFilters.length" #filters>
        <div
          class="start-picker__filters"
          role="group"
          :aria-label="t('hangarPlanner.fields.filters')"
        >
          <Chip
            v-for="status in shownFilters"
            :key="status"
            :state="
              filters.includes(status)
                ? ChipStatesEnum.INCLUDED
                : ChipStatesEnum.NEUTRAL
            "
            :count="filterCount(status)"
            :data-test="`hangar-plan-start-filter-${status}`"
            @toggle="toggleFilter(status)"
          >
            {{ t(`hangarPlanner.vehicleStatuses.${status}`) }}
          </Chip>
        </div>
      </template>
    </PickList>

    <template v-if="start || acquisition" #footer-start>
      <Btn
        v-if="start"
        :variant="BtnVariantsEnum.BARE"
        :disabled="pairing"
        data-test="hangar-plan-start-back"
        @click="start = undefined"
      >
        <i class="fa-light fa-arrow-left" />
        {{ t("hangarPlanner.pick.back") }}
      </Btn>
      <Btn
        v-else
        :variant="BtnVariantsEnum.BARE"
        :tone="BtnTonesEnum.DANGER"
        :disabled="pairing"
        data-test="hangar-plan-start-remove"
        @click="remove"
      >
        <i class="fa-light fa-xmark" />
        {{ t("hangarPlanner.pick.removeStart") }}
      </Btn>
    </template>
    <template v-if="candidate" #footer>
      <Btn
        :disabled="pairing"
        data-test="hangar-plan-start-other"
        @click="otherStarts"
      >
        <i class="fa-light fa-route" />
        {{ t("hangarPlanner.pick.otherStarts") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.start-picker__hint {
  margin: 0 0 12px;
  color: var(--color-text-dim);
}

.start-picker__filters {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
</style>
