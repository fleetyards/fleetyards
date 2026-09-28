<script lang="ts">
export default {
  name: "MissionsPickerModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import { type ModelPickerSelection } from "@/frontend/components/Models/PickerModal/types";
import { ModelProductionStatusEnum } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const comlink = useComlink();

// Any flight-ready ship: a contract can be flown in anything, and the marks
// only differ for the few that can't land.
const query = {
  productionStatusIn: [ModelProductionStatusEnum.FLIGHT_READY],
};

const submit = (selection: ModelPickerSelection[]) => {
  const [picked] = selection;
  if (picked) {
    comlink.emit("missions-model-picked", picked.option.slug);
  }

  comlink.emit("close-modal");
};
</script>

<template>
  <PickerModal
    :title="t('modelPicker.missionsTitle')"
    :submit-label="t('actions.missions.pickShip')"
    :query="query"
    hangar-filter
    single
    @submit="submit"
  />
</template>
