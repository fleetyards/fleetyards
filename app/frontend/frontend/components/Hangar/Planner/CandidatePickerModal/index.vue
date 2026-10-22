<script lang="ts">
export default {
  name: "HangarPlannerCandidatePickerModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import { type ModelPickerSelection } from "@/frontend/components/Models/PickerModal/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlanSlot,
  useCreateHangarPlanCandidate,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot: HangarPlanSlot;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

const submitting = ref(false);
const mutation = useCreateHangarPlanCandidate();

// The slot's filters bound the picker; its own filters narrow within them.
const query = computed(() => ({ ...props.slot.filters }));

const taken = computed(() =>
  props.slot.candidates.map((candidate) => candidate.model.slug),
);

// One request per ship, in order, so each answer carries every ship added
// before it and the last one is the whole slot.
const submit = async (selection: ModelPickerSelection[]) => {
  submitting.value = true;

  try {
    for (const { option } of selection) {
      updatePlan(
        await mutation.mutateAsync({
          hangarPlanId: props.planId,
          data: { slotId: props.slot.id, modelId: option.id },
        }),
      );
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
  />
</template>
