<script lang="ts">
export default {
  name: "HangarPlannerCandidatePickerModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import {
  type ModelPickerFilters,
  type ModelPickerSelection,
} from "@/frontend/components/Models/PickerModal/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import { startHolder } from "@/frontend/components/Hangar/Planner/reach";
import {
  type HangarPlanStart,
  useHangarPlanPairing,
} from "@/frontend/composables/useHangarPlanPairing";
import {
  type HangarPlan,
  type HangarPlanModel,
  type HangarPlanSlot,
  useCreateHangarPlanCandidate,
  useHangarPlan,
  useUpdateHangarPlanSlot,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot: HangarPlanSlot;
  // A start picked for the slot before it had a ship, saved with the ship; its
  // ship, where it is one already, bounds what the start can become.
  start?: HangarPlanStart;
  startModel?: HangarPlanModel;
};

const props = withDefaults(defineProps<Props>(), {
  start: undefined,
  startModel: undefined,
});

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert, displaySuccess } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

const submitting = ref(false);
const mutation = useCreateHangarPlanCandidate();

// The slot's filters bound the picker; its own filters narrow within them. A
// slot holds only ships the plan can get: on the store, in game, or already
// held or bought back.
const query = computed(() => ({
  ...props.slot.filters,
  playerOwnableEq: true,
  plannable: true,
  ...(props.startModel
    ? {
        ccuTarget: true,
        ...(typeof props.startModel.pledgePrice === "number"
          ? { pledgePriceGt: props.startModel.pledgePrice }
          : {}),
      }
    : {}),
}));

const taken = computed(() =>
  props.slot.candidates.map((candidate) => candidate.model.slug),
);

const { data: plan } = useHangarPlan(() => props.planId);
const { pairStart } = useHangarPlanPairing(() => props.planId, plan);

const updateSlot = useUpdateHangarPlanSlot();
const savingFilters = ref(false);

const picked = (filters: ModelPickerFilters) =>
  Object.values(filters).some((values) => values.length > 0);

// The lists picked here become the slot's own, beside the price and cargo
// bounds it already sets, so its picker opens on them next time.
const saveFilters = async (filters: ModelPickerFilters) => {
  savingFilters.value = true;

  const lists = Object.fromEntries(
    Object.entries(filters).filter(([, values]) => values.length > 0),
  );

  try {
    updatePlan(
      await updateSlot.mutateAsync({
        hangarPlanId: props.planId,
        id: props.slot.id,
        data: { filters: { ...props.slot.filters, ...lists } },
      }),
    );
    displaySuccess({
      text: t("hangarPlanner.messages.filtersSaved", {
        slot: props.slot.label,
      }),
    });
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    savingFilters.value = false;
  }
};

// One request per ship, in order, so each answer carries every ship added
// before it and the last one is the whole slot.
const submit = async (selection: ModelPickerSelection[]) => {
  submitting.value = true;

  try {
    let answer: HangarPlan | undefined;
    for (const { option } of selection) {
      answer = await mutation.mutateAsync({
        hangarPlanId: props.planId,
        data: { slotId: props.slot.id, modelId: option.id },
      });
      updatePlan(answer);
    }

    const holder = startHolder(
      answer?.slots.find((slot) => slot.id === props.slot.id)?.candidates ?? [],
      props.startModel,
    );
    if (props.start && holder) {
      const paired = await pairStart(holder, props.start);
      if (!paired) return;
    }

    comlink.emit("close-modal", true);
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <PickerModal
    :title="t('hangarPlanner.addCandidates', { slot: slot.label })"
    :submit-label="t('hangarPlanner.addToSlot')"
    :submitting="submitting"
    :taken-slugs="taken"
    :taken-note="t('hangarPlanner.inSlot')"
    :query="query"
    hangar-filter
    @submit="submit"
  >
    <template #filter-actions="{ filters }">
      <Btn
        v-if="picked(filters)"
        :variant="BtnVariantsEnum.BARE"
        :size="BtnSizesEnum.XS"
        :loading="savingFilters"
        data-test="hangar-plan-save-slot-filters"
        @click="saveFilters(filters)"
      >
        <i class="fa-light fa-floppy-disk" />
        {{ t("hangarPlanner.pick.saveFilters") }}
      </Btn>
    </template>
  </PickerModal>
</template>
