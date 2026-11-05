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
  type HangarPlan,
  type HangarPlanSlot,
  useCreateHangarPlanCandidate,
  useUpdateHangarPlanAcquisition,
  useUpdateHangarPlanSlot,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot: HangarPlanSlot;
};

const props = defineProps<Props>();

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
}));

const taken = computed(() =>
  props.slot.candidates.map((candidate) => candidate.model.slug),
);

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
const updateAcquisition = useUpdateHangarPlanAcquisition();

// The slot's first ship took the starts it held, before the ships picked with
// it existed; each now moves to the ship it comes closest to. A ship to buy or
// earn became the first one, so it is where it belongs.
const settleStarts = async (answer: HangarPlan) => {
  const candidates =
    answer.slots.find((slot) => slot.id === props.slot.id)?.candidates ?? [];

  for (const { id, startModel } of props.slot.starts) {
    const holder = startModel && startHolder(candidates, startModel);
    const moved =
      holder &&
      !holder.acquisitions.some((acquisition) => acquisition.id === id);

    if (moved) {
      updatePlan(
        await updateAcquisition.mutateAsync({
          hangarPlanId: props.planId,
          id,
          data: { candidateId: holder.id },
        }),
      );
    }
  }
};

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
    if (answer) await settleStarts(answer);

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
