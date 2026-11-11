<script lang="ts">
export default {
  name: "HangarPlannerEndView",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import ShipList from "@/frontend/components/Hangar/Planner/ShipPanel/ShipList/index.vue";
import ShipDetail from "@/frontend/components/Hangar/Planner/ShipPanel/ShipDetail/index.vue";
import UpgradeNote from "@/frontend/components/Hangar/Planner/ShipPanel/UpgradeNote/index.vue";
import type {
  ShipListItem,
  ShipListSection,
} from "@/frontend/components/Hangar/Planner/ShipPanel/ShipList/types";
import type { ShipListTag } from "@/frontend/components/Hangar/Planner/ShipPanel/ShipList/types";
import {
  manufacturerText,
  usePlanMoney,
} from "@/frontend/components/Hangar/Planner/format";
import {
  ccuNote,
  reaches,
  upgradeCost,
} from "@/frontend/components/Hangar/Planner/reach";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type HangarPlanEnd,
  useHangarPlanPairing,
} from "@/frontend/composables/useHangarPlanPairing";
import {
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanModel,
  type HangarPlanSlot,
  HangarPlanSlotStateEnum,
  useHangarPlan,
  useHangarPlanResources,
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

const emit = defineEmits<{
  done: [];
  editSlot: [slot: HangarPlanSlot];
}>();

const SAME = "same";
const MODEL = "model:";

const { t } = useI18n();
const { money } = usePlanMoney();

const { data: plan } = useHangarPlan(() => props.planId);
const { data: resources, isLoading } = useHangarPlanResources(
  () => props.planId,
);

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

// Any ship of the store the start can be upgraded into, beyond those the plan
// already holds a unit for; picking one gives it a slot of its own.
const catalogue = computed(() => {
  const start = props.startModel;
  if (!start) return [];

  const planned = new Set(
    ends.value.map(({ candidate }) => candidate.model.id),
  );

  return (resources.value?.storeModels ?? []).filter(
    (model) =>
      model.id !== start.id && !planned.has(model.id) && reaches(start, model),
  );
});

// How sure an upgrade into an end is, for one the start becomes by upgrading.
const upgradeTag = (model: HangarPlanModel): ShipListTag[] => {
  const note = ccuNote(model);

  return note && model.id !== props.startModel?.id
    ? [{ label: t(note), variant: PillVariantsEnum.WARNING }]
    : [];
};

const costFromStart = (model: HangarPlanModel) =>
  props.startModel ? upgradeCost(props.startModel, model) : undefined;

const sections = computed<ShipListSection[]>(() => [
  { key: "keep", label: t("hangarPlanner.panel.sections.keep") },
  {
    key: "plan",
    label: t("hangarPlanner.panel.sections.plan"),
    hint: t("hangarPlanner.panel.sections.planHint"),
  },
  {
    key: "store",
    label: t("hangarPlanner.panel.sections.store"),
    hint: t("hangarPlanner.panel.sections.storeHint"),
  },
]);

const shipItem = (
  model: HangarPlanModel,
  section: string,
  extra: Partial<ShipListItem>,
): ShipListItem => {
  const cost = costFromStart(model);

  return {
    id: model.id,
    section,
    title: model.name,
    ship: model,
    price: money(cost),
    priceNote: money(model.pledgePrice),
    sortPrice: cost,
    ...extra,
  };
};

const items = computed<ShipListItem[]>(() => [
  ...(props.vehicleId && props.startModel
    ? [
        {
          id: SAME,
          section: "keep",
          icon: "fa-light fa-equals",
          title: t("hangarPlanner.pick.same"),
          ship: props.startModel,
          meta: props.startModel.name,
          price: money(0),
          sortPrice: 0,
        },
      ]
    : []),
  ...ends.value.map(({ slot, candidate }) =>
    shipItem(candidate.model, "plan", {
      id: candidate.id,
      meta: manufacturerText(candidate.model),
      tags: [{ label: slot.label }, ...upgradeTag(candidate.model)],
      badge:
        candidate.model.id === props.startModel?.id
          ? t("hangarPlanner.pick.sameModel")
          : undefined,
    }),
  ),
  ...catalogue.value.map((model) =>
    shipItem(model, "store", {
      id: `${MODEL}${model.id}`,
      meta: manufacturerText(model),
      tags: upgradeTag(model),
    }),
  ),
]);

const candidateOf = (item: ShipListItem): HangarPlanCandidate | undefined =>
  ends.value.find((entry) => entry.candidate.id === item.id)?.candidate;

const slotOf = (item: ShipListItem) =>
  ends.value.find((entry) => entry.candidate.id === item.id)?.slot;

const modelOf = (item: ShipListItem) => item.ship;

const selected = ref<string>();

const target = () => ({
  vehicleId: props.vehicleId,
  acquisition: props.acquisition,
});

const pick = async (end: HangarPlanEnd) => {
  if (await pairEnd(end, target())) emit("done");
};

const choose = (item: ShipListItem) => {
  if (item.id === SAME) return pick({ kind: "same" });

  if (item.id.startsWith(MODEL)) {
    const model = catalogue.value.find(
      (entry) => `${MODEL}${entry.id}` === item.id,
    );
    return (
      model && pick({ kind: "model", modelId: model.id, name: model.name })
    );
  }

  const candidate = candidateOf(item);
  if (candidate) return pick({ kind: "candidate", candidate });
};

const removable = computed(() => !!props.acquisition || !!props.vehicleId);
</script>

<template>
  <div class="panel-view" data-test="hangar-plan-end-picker">
    <div class="panel-view__body">
      <p v-if="startModel" class="panel-view__muted">
        {{ t("hangarPlanner.panel.endsHint") }}
      </p>
      <ShipList
        v-model="selected"
        name="end"
        :sections="sections"
        :items="items"
        :loading="isLoading"
        :price-label="t('hangarPlanner.panel.upgradeCost')"
        :empty="t('hangarPlanner.pick.noEnds')"
        @commit="choose"
      >
        <template #detail="{ item }">
          <ShipDetail
            :title="modelOf(item)?.name ?? item.title"
            :ship="modelOf(item)"
            :sub="item.id === SAME ? t('hangarPlanner.pick.same') : undefined"
            :action-label="t('hangarPlanner.panel.useEnd')"
            :busy="pairing"
            @commit="choose(item)"
          >
            <UpgradeNote
              v-if="startModel && modelOf(item) && item.id !== SAME"
              :from="startModel"
              :to="modelOf(item)!"
            />
            <p v-if="slotOf(item)" class="panel-view__muted">
              {{
                t("hangarPlanner.panel.fillsSlot", {
                  slot: slotOf(item)!.label,
                })
              }}
            </p>
            <p v-else-if="item.id.startsWith(MODEL)" class="panel-view__muted">
              {{ t("hangarPlanner.panel.newSlotHint") }}
            </p>
          </ShipDetail>
        </template>
      </ShipList>
    </div>

    <footer v-if="removable || slot" class="panel-view__footer">
      <Btn
        v-if="removable"
        :variant="BtnVariantsEnum.BARE"
        :tone="BtnTonesEnum.DANGER"
        :disabled="pairing"
        data-test="hangar-plan-end-remove"
        @click="pick({ kind: 'remove' })"
      >
        <i class="fa-light fa-xmark" />
        {{ t("hangarPlanner.pick.removeEnd") }}
      </Btn>
      <Btn
        v-if="slot"
        :disabled="pairing"
        data-test="hangar-plan-end-edit-slot"
        @click="emit('editSlot', slot)"
      >
        <i class="fa-light fa-pen" />
        {{ t("hangarPlanner.editSlot") }}
      </Btn>
    </footer>
  </div>
</template>

<style lang="scss" scoped src="../view.scss"></style>
