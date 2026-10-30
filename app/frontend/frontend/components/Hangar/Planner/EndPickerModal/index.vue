<script lang="ts">
export default {
  name: "HangarPlannerEndPickerModal",
};
</script>

<script lang="ts" setup>
import type { Component } from "vue";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import PickList, {
  type PickListItem,
} from "@/frontend/components/Hangar/Planner/PickList/index.vue";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { reaches } from "@/frontend/components/Hangar/Planner/reach";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type HangarPlanEnd,
  useHangarPlanPairing,
} from "@/frontend/composables/useHangarPlanPairing";
import {
  type HangarPlanAcquisition,
  type HangarPlanModel,
  type HangarPlanSlot,
  HangarPlanSlotStateEnum,
  useHangarPlan,
} from "@/services/fyApi";

type Props = {
  planId: string;
  // What the route starts from: a hangar ship, or the start of a planned route.
  startName: string;
  startModel?: HangarPlanModel;
  vehicleId?: string;
  acquisition?: HangarPlanAcquisition;
  // The slot the route ends in now, which can be edited from here.
  slot?: HangarPlanSlot;
};

const props = withDefaults(defineProps<Props>(), {
  startModel: undefined,
  vehicleId: undefined,
  acquisition: undefined,
  slot: undefined,
});

const SAME = "same";

const { t } = useI18n();
const { money } = usePlanMoney();
const comlink = useComlink();

const { data: plan } = useHangarPlan(() => props.planId);

const { pairing, pairEnd } = useHangarPlanPairing(() => props.planId, plan);

// A ship of a decided slot with a unit left, which a route can end on.
const ends = computed(() =>
  (plan.value?.slots ?? []).flatMap((slot) => {
    const candidate = slot.candidates[0];
    if (slot.state !== HangarPlanSlotStateEnum.DECIDED || !candidate) return [];
    if (slot.id === props.slot?.id) return [];
    // A route upgrades towards its end, so only the same ship, or a dearer
    // one both ends can be upgraded to, is in reach.
    const start = props.startModel;
    if (start && !reaches(start, candidate.model)) return [];

    const taken = candidate.acquisitions.filter(
      (entry) => entry.id !== props.acquisition?.id,
    ).length;

    return taken < slot.quantity ? [{ slot, candidate }] : [];
  }),
);

const items = computed<PickListItem[]>(() => [
  ...(props.vehicleId && props.startModel
    ? [
        {
          id: SAME,
          title: t("hangarPlanner.pick.same"),
          meta: props.startModel.name,
          price: money(0),
          sortPrice: 0,
          pinned: true,
        },
      ]
    : []),
  ...ends.value.map(({ slot, candidate }) => ({
    id: candidate.id,
    title: candidate.model.name,
    meta: slot.label,
    price: money(candidate.model.pledgePrice),
    sortPrice: candidate.model.pledgePrice,
    badge:
      candidate.model.id === props.startModel?.id
        ? t("hangarPlanner.pick.sameModel")
        : undefined,
  })),
]);

const close = () => comlink.emit("close-modal", true);

const target = () => ({
  vehicleId: props.vehicleId,
  acquisition: props.acquisition,
});

const pick = async (end: HangarPlanEnd) => {
  if (await pairEnd(end, target())) close();
};

const choose = (item: PickListItem) => {
  if (item.id === SAME) return pick({ kind: "same" });

  const end = ends.value.find((entry) => entry.candidate.id === item.id);
  if (end) return pick({ kind: "candidate", candidate: end.candidate });
};

// No upgrade leads out of some ships, so they end nowhere but as themselves.
const upgradable = computed(() => props.startModel?.upgradable !== false);

const removable = computed(() => !!props.acquisition || !!props.vehicleId);

const openModal = (
  component: () => Promise<Component>,
  modalProps: Record<string, unknown>,
) =>
  comlink.emit("open-modal", {
    component,
    props: { planId: props.planId, ...modalProps },
  });

const anyShip = () =>
  openModal(
    () =>
      import("@/frontend/components/Hangar/Planner/UpgradeTargetModal/index.vue"),
    { ...target(), startName: props.startName },
  );

const editSlot = () =>
  openModal(
    () =>
      import("@/frontend/components/Hangar/Planner/SlotShipsModal/index.vue"),
    { slot: props.slot },
  );
</script>

<template>
  <Modal
    :title="t('hangarPlanner.pick.endTitle', { ship: startName })"
    :eyebrow="t('hangarPlanner.pick.endEyebrow')"
  >
    <PickList
      name="hangar-plan-end"
      :items="items"
      :action-label="t('hangarPlanner.pick.use')"
      :empty="t('hangarPlanner.pick.noEnds')"
      data-test="hangar-plan-end-picker"
      @pick="choose"
    />

    <template v-if="removable" #footer-start>
      <Btn
        :variant="BtnVariantsEnum.BARE"
        :tone="BtnTonesEnum.DANGER"
        :disabled="pairing"
        data-test="hangar-plan-end-remove"
        @click="pick({ kind: 'remove' })"
      >
        <i class="fa-light fa-xmark" />
        {{ t("hangarPlanner.pick.removeEnd") }}
      </Btn>
    </template>
    <template #footer>
      <Btn
        v-if="slot"
        :disabled="pairing"
        data-test="hangar-plan-end-edit-slot"
        @click="editSlot"
      >
        <i class="fa-light fa-pen" />
        {{ t("hangarPlanner.editSlot") }}
      </Btn>
      <Btn
        v-if="upgradable"
        :disabled="pairing"
        data-test="hangar-plan-end-any"
        @click="anyShip"
      >
        <i class="fa-light fa-magnifying-glass" />
        {{ t("hangarPlanner.pick.anyShip") }}
      </Btn>
    </template>
  </Modal>
</template>
