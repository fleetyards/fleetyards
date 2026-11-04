<script lang="ts">
export default {
  name: "FleetchartCanvasAddShipsModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import {
  ModelPickerBadge,
  type ModelPickerSelection,
} from "@/frontend/components/Models/PickerModal/types";
import type { ModelQuery } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  add: (selection: ModelPickerSelection[]) => void;
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

// A ship without pictures could be added but never drawn.
const drawableOnly: ModelQuery = { hasFleetchartViews: true };

const submit = (selection: ModelPickerSelection[]) => {
  props.add(selection);

  // The picker reports its selection as unsaved; it has been used.
  comlink.emit("close-modal", true);
};
</script>

<template>
  <PickerModal
    :title="t('labels.fleetchartApp.addShips')"
    :submit-label="t('labels.fleetchartApp.addShips')"
    :query="drawableOnly"
    :highlight="ModelPickerBadge.IN_HANGAR"
    quantities
    @submit="submit"
  />
</template>
