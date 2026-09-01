<script lang="ts">
export default {
  name: "CompareModelsPickerModal",
};
</script>

<script lang="ts" setup>
import PickerModal from "@/frontend/components/Models/PickerModal/index.vue";
import { type ModelPickerSelection } from "@/frontend/components/Models/PickerModal/types";
import { MAX_MODELS } from "@/frontend/components/Compare/constants";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { uniq as uniqArray } from "@/shared/utils/Array";

const { t } = useI18n();

const comlink = useComlink();

const { filter, filters } = useCompareModelFilters();

// Read once, at open: the picker adds to the set the page had when it was opened,
// and the query it writes on submit closes the modal with it.
const compared = filters.value.models;

const submit = (selection: ModelPickerSelection[]) => {
  // Appended, not sorted: the query carries slugs and the table orders its
  // columns by ship name, so sorting here only decided which slug order the URL
  // happened to carry.
  filter({
    models: [...compared, ...selection.map(({ option }) => option.slug)].filter(
      uniqArray,
    ),
  });

  comlink.emit("close-modal");
};
</script>

<template>
  <PickerModal
    :title="t('modelPicker.compareTitle')"
    :submit-label="t('actions.compare.ships')"
    :max="MAX_MODELS - compared.length"
    :max-hint="t('labels.compare.enough')"
    :taken-slugs="compared"
    :taken-note="t('modelPicker.badges.comparing')"
    @submit="submit"
  />
</template>
