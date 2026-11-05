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
import PledgeInfo from "@/frontend/components/Hangar/Planner/PledgeInfo/index.vue";
import PickList, {
  type PickListItem,
} from "@/frontend/components/Hangar/Planner/PickList/index.vue";
import {
  manufacturerText,
  usePlanMoney,
  usePledgeNote,
} from "@/frontend/components/Hangar/Planner/format";
import {
  reaches,
  startHolder,
} from "@/frontend/components/Hangar/Planner/reach";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useBuybackInsurance } from "@/frontend/composables/useBuybackInsurance";
import {
  type HangarPlanStart,
  useHangarPlanPairing,
} from "@/frontend/composables/useHangarPlanPairing";
import {
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanModel,
  type HangarPlanSlot,
  type HangarPlanSlotStart,
  BuybackPledgeKindEnum,
  HangarPlanVehicleStatusEnum,
  useHangarPlan,
  useHangarPlanComparison,
  useHangarPlanResources,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot: HangarPlanSlot;
  // The ship the start leads to; unset for a slot still choosing its ship.
  candidate?: HangarPlanCandidate;
  acquisition?: HangarPlanAcquisition | HangarPlanSlotStart;
};

const props = withDefaults(defineProps<Props>(), {
  candidate: undefined,
  acquisition: undefined,
});

const STORE = "store";

// What a hangar ship free for a start can be in the plan so far. One already
// decided on - kept as it is, given a route, melted - is no start any more.
const FILTERS = [
  HangarPlanVehicleStatusEnum.CHANGE,
  HangarPlanVehicleStatusEnum.PENDING,
  HangarPlanVehicleStatusEnum.UNASSIGNED,
];

const { t } = useI18n();
const { money } = usePlanMoney();
const pledgeNote = usePledgeNote();
const comlink = useComlink();

const { data: plan } = useHangarPlan(() => props.planId);
const { data: comparison } = useHangarPlanComparison(() => props.planId);
const { data: resources, isLoading } = useHangarPlanResources(
  () => props.planId,
);

const { pairing, pairStart, holdStart, pairEnd } = useHangarPlanPairing(
  () => props.planId,
  plan,
);

const target = computed(() => props.candidate?.model);

// A slot still choosing its ship is reached by a start that can become at
// least one of its ships; the ones it cannot become are named on it. With no
// ship to choose from yet, any ship can start: it may be the one the slot gets.
const unreachedShips = (from: HangarPlanModel) =>
  props.slot.candidates
    .map((candidate) => candidate.model)
    .filter((ship) => !reaches(from, ship));

const reachesSlot = (from: HangarPlanModel) =>
  props.slot.candidates.length
    ? unreachedShips(from).length < props.slot.candidates.length
    : true;

const excludes = (from: HangarPlanModel) => {
  if (target.value) return undefined;

  const ships = unreachedShips(from);
  if (!ships.length) return undefined;

  return t("hangarPlanner.pick.excludes", {
    ships: ships.map((ship) => ship.name).join(", "),
  });
};

const statusOf = (vehicleId: string) =>
  comparison.value?.vehicles.find((entry) => entry.vehicleId === vehicleId)
    ?.status;

const freeVehicles = computed(() =>
  (resources.value?.vehicles ?? []).filter(
    (vehicle) =>
      (vehicle.id === props.acquisition?.sourceVehicleId ||
        (!vehicle.usedBy &&
          statusOf(vehicle.id) !== HangarPlanVehicleStatusEnum.KEPT)) &&
      (target.value
        ? reaches(vehicle.model, target.value)
        : reachesSlot(vehicle.model)),
  ),
);

type Source = "hangar" | "buyback" | "store";

type StartOption = {
  item: PickListItem;
  source: Source;
  start: HangarPlanStart;
  // The ship the start is; unset for a store purchase of the ship still to
  // be picked.
  model?: HangarPlanModel;
  status?: HangarPlanVehicleStatusEnum;
};

const SOURCES: Source[] = ["hangar", "buyback", "store"];

const insuranceLabel = useBuybackInsurance();

const startBadge = (model: HangarPlanModel) =>
  model.id === target.value?.id
    ? t("hangarPlanner.route.isTarget")
    : excludes(model);

const fits = (model: HangarPlanModel) =>
  target.value ? reaches(model, target.value) : reachesSlot(model);

const vehicleOptions = computed<StartOption[]>(() =>
  freeVehicles.value.map((vehicle) => {
    const status = statusOf(vehicle.id);

    return {
      source: "hangar",
      start: { kind: "owned", vehicleId: vehicle.id },
      model: vehicle.model,
      status,
      item: {
        id: `vehicle:${vehicle.id}`,
        title: vehicle.name || vehicle.model.name,
        meta: [
          vehicle.name ? vehicle.model.name : manufacturerText(vehicle.model),
          pledgeNote(vehicle),
        ]
          .filter(Boolean)
          .join(" · "),
        tags: status
          ? [{ label: t(`hangarPlanner.vehicleStatuses.${status}`) }]
          : [],
        price: money(vehicle.model.pledgePrice),
        sortPrice: vehicle.model.pledgePrice,
        badge:
          vehicle.id === props.acquisition?.sourceVehicleId
            ? t("hangarPlanner.pick.current")
            : startBadge(vehicle.model),
        pinned: !!target.value && vehicle.model.id === target.value.id,
      },
    };
  }),
);

// A pledge to buy back starts as the ship it holds that comes closest: the
// planned ship itself, else the dearest one that can still become it.
const buybackShip = (models: HangarPlanModel[]) => {
  const fitting = models.filter(fits);

  return (
    fitting.find((model) => model.id === target.value?.id) ??
    [...fitting].sort((a, b) => (b.pledgePrice ?? 0) - (a.pledgePrice ?? 0))[0]
  );
};

const buybackOptions = computed<StartOption[]>(() =>
  (resources.value?.buybacks ?? []).flatMap((pledge): StartOption[] => {
    if (pledge.kind === BuybackPledgeKindEnum.UPGRADE) return [];
    if (pledge.used && pledge.id !== props.acquisition?.buybackPledgeId) {
      return [];
    }

    const model = buybackShip(pledge.models);
    if (!model) return [];

    return [
      {
        source: "buyback",
        start: { kind: "buyback", pledgeId: pledge.id, modelId: model.id },
        model,
        item: {
          id: `buyback:${pledge.id}`,
          title: pledge.name,
          meta: [model.name, insuranceLabel(pledge)].join(" · "),
          keywords: pledge.models.map((entry) => entry.name).join(" "),
          price: money(pledge.price),
          sortPrice: pledge.price,
          badge:
            pledge.id === props.acquisition?.buybackPledgeId
              ? t("hangarPlanner.pick.current")
              : startBadge(model),
          pinned: !!target.value && model.id === target.value.id,
        },
      },
    ];
  }),
);

const storeOption = computed<StartOption>(() => ({
  source: "store",
  start: { kind: "store" },
  model: target.value,
  item: {
    id: STORE,
    title: t("hangarPlanner.pick.buyNew"),
    meta: target.value?.name ?? t("hangarPlanner.pick.buyChosen"),
    price: target.value ? money(target.value.pledgePrice) : undefined,
    sortPrice: target.value?.pledgePrice,
    pinned: true,
  },
}));

// Earned in game, a ship takes no upgrades, so it starts as the ship itself.
const ingameOption = computed<StartOption>(() => ({
  source: "store",
  start: { kind: "ingame" },
  model: target.value,
  item: {
    id: "ingame",
    title: t("hangarPlanner.pick.earnInGame"),
    meta: target.value?.name ?? t("hangarPlanner.pick.buyChosen"),
    price: money(0),
    sortPrice: 0,
  },
}));

const options = computed(() => [
  storeOption.value,
  ingameOption.value,
  ...vehicleOptions.value,
  ...buybackOptions.value,
]);

const sources = ref<Source[]>([]);
const statuses = ref<HangarPlanVehicleStatusEnum[]>([]);

const toggled = <T,>(list: T[], value: T) =>
  list.includes(value)
    ? list.filter((entry) => entry !== value)
    : [...list, value];

const toggleSource = (source: Source) => {
  sources.value = toggled(sources.value, source);
};

const toggleStatus = (status: HangarPlanVehicleStatusEnum) => {
  statuses.value = toggled(statuses.value, status);
};

const sourceCount = (source: Source) =>
  options.value.filter((option) => option.source === source).length;

const statusCount = (status: HangarPlanVehicleStatusEnum) =>
  vehicleOptions.value.filter((option) => option.status === status).length;

const shownSources = computed(() =>
  SOURCES.filter((source) => sourceCount(source) > 0),
);

// What a hangar ship was marked in the plan narrows the hangar ships only, so
// it is offered while they are in the list.
const shownStatuses = computed(() =>
  !sources.value.length || sources.value.includes("hangar")
    ? FILTERS.filter((status) => statusCount(status) > 0)
    : [],
);

const shown = (option: StartOption) =>
  (!sources.value.length || sources.value.includes(option.source)) &&
  (!statuses.value.length ||
    (option.status !== undefined && statuses.value.includes(option.status)));

const startItems = computed<PickListItem[]>(() =>
  options.value
    .filter(shown)
    .map((option) => ({ ...option.item, ship: option.model })),
);

// A hangar ship's package, whose contents open beside its row.
const packagedVehicle = (item: PickListItem) =>
  freeVehicles.value.find(
    (vehicle) =>
      `vehicle:${vehicle.id}` === item.id && vehicle.standalone === false,
  );

const close = () => comlink.emit("close-modal", true);

const chooseStart = async (item: PickListItem) => {
  const option = options.value.find((entry) => entry.item.id === item.id);
  if (!option) return;

  if (!props.candidate && !props.slot.candidates.length) {
    if (await holdStart(props.slot, option.start, props.acquisition)) close();
    return;
  }

  const candidate =
    props.candidate ?? startHolder(props.slot.candidates, option.model);
  if (!candidate) return;

  if (await pairStart(candidate, option.start, props.acquisition)) close();
};

const remove = async () => {
  if (await pairEnd({ kind: "remove" }, { acquisition: props.acquisition })) {
    close();
  }
};
</script>

<template>
  <Modal
    :title="
      t('hangarPlanner.pick.startTitle', { ship: target?.name ?? slot.label })
    "
    :eyebrow="t('hangarPlanner.pick.startEyebrow')"
  >
    <PickList
      name="hangar-plan-start"
      :items="startItems"
      :loading="isLoading"
      actions
      :empty="t('hangarPlanner.pick.noShips')"
      data-test="hangar-plan-start-picker"
      @pick="chooseStart"
    >
      <template v-if="shownSources.length > 1 || shownStatuses.length" #filters>
        <div
          class="start-picker__filters"
          role="group"
          :aria-label="t('hangarPlanner.pick.filters')"
        >
          <template v-if="shownSources.length > 1">
            <Chip
              v-for="source in shownSources"
              :key="source"
              :state="
                sources.includes(source)
                  ? ChipStatesEnum.INCLUDED
                  : ChipStatesEnum.NEUTRAL
              "
              :count="sourceCount(source)"
              :data-test="`hangar-plan-start-source-${source}`"
              @toggle="toggleSource(source)"
            >
              {{ t(`hangarPlanner.pick.sources.${source}`) }}
            </Chip>
          </template>
          <Chip
            v-for="status in shownStatuses"
            :key="status"
            :state="
              statuses.includes(status)
                ? ChipStatesEnum.INCLUDED
                : ChipStatesEnum.NEUTRAL
            "
            :count="statusCount(status)"
            :data-test="`hangar-plan-start-filter-${status}`"
            @toggle="toggleStatus(status)"
          >
            {{ t(`hangarPlanner.vehicleStatuses.${status}`) }}
          </Chip>
        </div>
      </template>
      <template #row-aside="{ item }">
        <PledgeInfo
          v-if="packagedVehicle(item)"
          :ship="packagedVehicle(item)!"
          :pledge="packagedVehicle(item)!"
        />
      </template>
    </PickList>

    <template v-if="acquisition" #footer-start>
      <Btn
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
  </Modal>
</template>

<style lang="scss" scoped>
.start-picker__filters {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
</style>
