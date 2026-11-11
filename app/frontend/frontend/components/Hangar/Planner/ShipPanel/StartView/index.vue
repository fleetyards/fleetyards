<script lang="ts">
export default {
  name: "HangarPlannerStartView",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import MeltContents from "@/frontend/components/Hangar/Planner/MeltContents/index.vue";
import ShipList from "@/frontend/components/Hangar/Planner/ShipPanel/ShipList/index.vue";
import ShipDetail from "@/frontend/components/Hangar/Planner/ShipPanel/ShipDetail/index.vue";
import UpgradeNote from "@/frontend/components/Hangar/Planner/ShipPanel/UpgradeNote/index.vue";
import type {
  ShipListItem,
  ShipListSection,
} from "@/frontend/components/Hangar/Planner/ShipPanel/ShipList/types";
import {
  manufacturerText,
  usePlanMoney,
  usePledgeNote,
} from "@/frontend/components/Hangar/Planner/format";
import {
  canEnter,
  canLeave,
  entersFrom,
  reaches,
  startHolder,
  upgradeCost,
} from "@/frontend/components/Hangar/Planner/reach";
import { useI18n } from "@/shared/composables/useI18n";
import { useBuybackInsurance } from "@/frontend/composables/useBuybackInsurance";
import {
  type HangarPlanStart,
  useHangarPlanPairing,
} from "@/frontend/composables/useHangarPlanPairing";
import {
  type HangarPlanAcquisition,
  type HangarPlanBuybackResource,
  type HangarPlanCandidate,
  type HangarPlanModel,
  type HangarPlanSlot,
  type HangarPlanSlotStart,
  type HangarPlanVehicleResource,
  BuybackPledgeKindEnum,
  HangarPlanVehicleStatusEnum,
  NullableHangarPlanVehicleUseEnum,
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

const emit = defineEmits<{
  done: [];
}>();

const { t } = useI18n();
const { money } = usePlanMoney();
const pledgeNote = usePledgeNote();
const insuranceLabel = useBuybackInsurance();

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
// least one of its ships. With no ship to choose from yet, any ship can start:
// it may be the one the slot gets.
const reachesSlot = (from: HangarPlanModel) =>
  !props.slot.candidates.length ||
  props.slot.candidates.some((candidate) => reaches(from, candidate.model));

const fits = (model: HangarPlanModel) =>
  target.value ? reaches(model, target.value) : reachesSlot(model);

// Why a ship cannot become the planned one, in the terms the reach rules use.
const unreachable = (from: HangarPlanModel) => {
  const to = target.value;
  if (!to) return t("hangarPlanner.panel.out.noneOfSlot");
  if (!canLeave(from)) return t("hangarPlanner.panel.out.noLeave");
  if (!canEnter(to)) {
    return t("hangarPlanner.panel.out.noEnter", { ship: to.name });
  }
  if (!entersFrom(from, to)) {
    return t("hangarPlanner.panel.out.hull", { ship: to.name });
  }

  return t("hangarPlanner.panel.out.dearer", {
    price: money(from.pledgePrice),
    ship: to.name,
    target: money(to.pledgePrice),
  });
};

// A start for a slot still choosing its ship names the ships it rules out.
const excludes = (from: HangarPlanModel) => {
  if (target.value) return undefined;

  const ships = props.slot.candidates
    .map((candidate) => candidate.model)
    .filter((ship) => !reaches(from, ship));
  if (!ships.length) return undefined;

  return t("hangarPlanner.pick.excludes", {
    ships: ships.map((ship) => ship.name).join(", "),
  });
};

const statusOf = (vehicleId: string) =>
  comparison.value?.vehicles.find((entry) => entry.vehicleId === vehicleId)
    ?.status;

// What upgrading a start into the planned ship costs on top of it.
const costToTarget = (from?: HangarPlanModel) =>
  from && target.value ? upgradeCost(from, target.value) : 0;

const plus = (...values: (number | null | undefined)[]) =>
  values.some((value) => typeof value !== "number")
    ? undefined
    : (values as number[]).reduce((sum, value) => sum + value, 0);

type StartOption = {
  item: ShipListItem;
  start?: HangarPlanStart;
  model?: HangarPlanModel;
  vehicle?: HangarPlanVehicleResource;
};

const sections = computed<ShipListSection[]>(() => [
  { key: "new", label: t("hangarPlanner.panel.sections.new") },
  {
    key: "hangar",
    label: t("hangarPlanner.panel.sections.hangar"),
    hint: t("hangarPlanner.panel.sections.hangarHint"),
  },
  { key: "buyback", label: t("hangarPlanner.panel.sections.buybacks") },
  {
    key: "out",
    label: target.value
      ? t("hangarPlanner.panel.sections.outOf", { ship: target.value.name })
      : t("hangarPlanner.panel.sections.out"),
  },
]);

const isCurrentVehicle = (vehicle: HangarPlanVehicleResource) =>
  vehicle.id === props.acquisition?.sourceVehicleId;

// Why a hangar ship is not free to start this route, if it is not.
const takenReason = (vehicle: HangarPlanVehicleResource) => {
  if (isCurrentVehicle(vehicle)) return undefined;
  if (vehicle.usedBy === NullableHangarPlanVehicleUseEnum.MELT) {
    return t("hangarPlanner.panel.out.melted");
  }
  if (vehicle.usedBy) return t("hangarPlanner.panel.out.used");
  if (statusOf(vehicle.id) === HangarPlanVehicleStatusEnum.KEPT) {
    return t("hangarPlanner.panel.out.kept");
  }

  return undefined;
};

const vehicleOptions = computed<StartOption[]>(() =>
  (resources.value?.vehicles ?? []).map((vehicle) => {
    const status = statusOf(vehicle.id);
    const reason =
      takenReason(vehicle) ??
      (fits(vehicle.model) ? undefined : unreachable(vehicle.model));
    const cost = costToTarget(vehicle.model);

    return {
      start: { kind: "owned", vehicleId: vehicle.id },
      model: vehicle.model,
      vehicle,
      item: {
        id: `vehicle:${vehicle.id}`,
        section: reason ? "out" : "hangar",
        reason,
        ship: vehicle.model,
        title: vehicle.name || vehicle.model.name,
        meta: [
          vehicle.name ? vehicle.model.name : manufacturerText(vehicle.model),
          pledgeNote(vehicle),
        ]
          .filter(Boolean)
          .join(" · "),
        tags:
          status && status !== HangarPlanVehicleStatusEnum.KEPT
            ? [
                {
                  label: t(`hangarPlanner.vehicleStatuses.${status}`),
                  variant:
                    status === HangarPlanVehicleStatusEnum.CHANGE
                      ? PillVariantsEnum.WARNING
                      : PillVariantsEnum.NEUTRAL,
                },
              ]
            : [],
        price: money(cost),
        priceNote: t("hangarPlanner.panel.worth", {
          price: money(vehicle.model.pledgePrice),
        }),
        sortPrice: cost,
        badge: isCurrentVehicle(vehicle)
          ? t("hangarPlanner.pick.current")
          : excludes(vehicle.model),
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

const isCurrentPledge = (pledge: HangarPlanBuybackResource) =>
  pledge.id === props.acquisition?.buybackPledgeId;

const buybackOptions = computed<StartOption[]>(() =>
  (resources.value?.buybacks ?? []).flatMap((pledge): StartOption[] => {
    if (pledge.kind === BuybackPledgeKindEnum.UPGRADE) return [];

    const model = buybackShip(pledge.models);
    const shown = model ?? pledge.models[0];
    if (!shown) return [];

    const reason =
      pledge.used && !isCurrentPledge(pledge)
        ? t("hangarPlanner.panel.out.used")
        : model
          ? undefined
          : unreachable(shown);
    const cost = plus(pledge.price, costToTarget(model));

    return [
      {
        start: model
          ? { kind: "buyback", pledgeId: pledge.id, modelId: model.id }
          : undefined,
        model: shown,
        item: {
          id: `buyback:${pledge.id}`,
          section: reason ? "out" : "buyback",
          reason,
          ship: shown,
          title: pledge.name,
          meta: [shown.name, insuranceLabel(pledge)].join(" · "),
          keywords: pledge.models.map((entry) => entry.name).join(" "),
          price: money(cost),
          priceNote: t("hangarPlanner.panel.buybackPrice", {
            price: money(pledge.price),
          }),
          sortPrice: cost,
          badge: isCurrentPledge(pledge)
            ? t("hangarPlanner.pick.current")
            : excludes(shown),
          pinned: !!target.value && shown.id === target.value.id,
        },
      },
    ];
  }),
);

const newOptions = computed<StartOption[]>(() => [
  {
    start: { kind: "store" },
    model: target.value,
    item: {
      id: "store",
      section: "new",
      icon: "fa-light fa-cart-shopping",
      title: t("hangarPlanner.pick.buyNew"),
      meta: target.value?.name ?? t("hangarPlanner.pick.buyChosen"),
      price: target.value ? money(target.value.pledgePrice) : undefined,
      sortPrice: target.value?.pledgePrice,
    },
  },
  // Earned in game, a ship takes no upgrades, so it starts as the ship itself.
  {
    start: { kind: "ingame" },
    model: target.value,
    item: {
      id: "ingame",
      section: "new",
      icon: "fa-light fa-coins",
      title: t("hangarPlanner.pick.earnInGame"),
      meta: target.value?.name ?? t("hangarPlanner.pick.buyChosen"),
      price: money(0),
      sortPrice: 0,
    },
  },
]);

const options = computed(() => [
  ...newOptions.value,
  ...vehicleOptions.value,
  ...buybackOptions.value,
]);

const items = computed(() => options.value.map((option) => option.item));

const optionOf = (item: ShipListItem) =>
  options.value.find((option) => option.item.id === item.id);

const currentId = computed(() => {
  if (props.acquisition?.sourceVehicleId) {
    return `vehicle:${props.acquisition.sourceVehicleId}`;
  }
  if (props.acquisition?.buybackPledgeId) {
    return `buyback:${props.acquisition.buybackPledgeId}`;
  }
  return undefined;
});

const selected = ref<string | undefined>(currentId.value);

const choose = async (item: ShipListItem) => {
  const option = optionOf(item);
  if (!option?.start) return;

  if (!props.candidate && !props.slot.candidates.length) {
    if (await holdStart(props.slot, option.start, props.acquisition)) {
      emit("done");
    }
    return;
  }

  const candidate =
    props.candidate ?? startHolder(props.slot.candidates, option.model);
  if (!candidate) return;

  if (await pairStart(candidate, option.start, props.acquisition)) {
    emit("done");
  }
};

const remove = async () => {
  if (await pairEnd({ kind: "remove" }, { acquisition: props.acquisition })) {
    emit("done");
  }
};
</script>

<template>
  <div class="panel-view" data-test="hangar-plan-start-picker">
    <div class="panel-view__body">
      <ShipList
        v-model="selected"
        name="start"
        :sections="sections"
        :items="items"
        :loading="isLoading"
        :price-label="t('hangarPlanner.panel.youPay')"
        :empty="t('hangarPlanner.pick.noShips')"
        @commit="choose"
      >
        <template #detail="{ item }">
          <ShipDetail
            :title="optionOf(item)?.model?.name ?? item.title"
            :ship="optionOf(item)?.model"
            :sub="item.meta"
            :action-label="t('hangarPlanner.panel.useStart')"
            :busy="pairing"
            @commit="choose(item)"
          >
            <section
              v-if="optionOf(item)?.vehicle?.standalone === false"
              class="panel-view__block"
            >
              <h4 class="panel-view__label">
                {{ t("hangarPlanner.panel.package") }}
              </h4>
              <span>
                {{
                  optionOf(item)?.vehicle?.pledgeName ||
                  t("hangarPlanner.pledge.package")
                }}
              </span>
              <MeltContents
                :ships="optionOf(item)?.vehicle?.pledgeShips ?? []"
                :items="optionOf(item)?.vehicle?.pledgeItems ?? []"
              />
            </section>
            <UpgradeNote
              v-if="
                target &&
                optionOf(item)?.model &&
                optionOf(item)?.model?.id !== target.id
              "
              :from="optionOf(item)!.model!"
              :to="target"
            />
          </ShipDetail>
        </template>
      </ShipList>
    </div>

    <footer v-if="acquisition" class="panel-view__footer">
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
    </footer>
  </div>
</template>

<style lang="scss" scoped>
@use "../view";
</style>
