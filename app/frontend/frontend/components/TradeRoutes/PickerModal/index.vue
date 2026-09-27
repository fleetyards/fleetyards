<script lang="ts">
export default {
  name: "TradeRoutesPickerModal",
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

// Only ships whose holds we can measure: without a cargo grid there is no load
// to rank by.
const query = {
  withCargoGrids: true,
  productionStatusIn: [ModelProductionStatusEnum.FLIGHT_READY],
};

const submit = (selection: ModelPickerSelection[]) => {
  const [picked] = selection;
  if (picked) {
    comlink.emit("trade-routes-model-picked", picked.option.slug);
  }

  comlink.emit("close-modal");
};
</script>

<template>
  <PickerModal
    :title="t('modelPicker.tradeRoutesTitle')"
    :submit-label="t('actions.tradeRoutes.pickShip')"
    :query="query"
    hangar-filter
    single
    @submit="submit"
  />
</template>
