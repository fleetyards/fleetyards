<script lang="ts">
export default {
  name: "CompareModelsForm",
};
</script>

<script lang="ts" setup>
import CompareAddButton from "@/frontend/components/Compare/AddButton/index.vue";
import { MAX_MODELS } from "@/frontend/components/Compare/constants";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  compact?: boolean;
};

withDefaults(defineProps<Props>(), {
  compact: false,
});

const { t } = useI18n();

const comlink = useComlink();

const { filters } = useCompareModelFilters();

const showPickerModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Compare/Models/PickerModal/index.vue"),
    wide: true,
  });
};
</script>

<template>
  <CompareAddButton
    :label="t('labels.compare.selectShips')"
    :full="filters.models.length >= MAX_MODELS"
    :full-hint="t('labels.compare.enough')"
    :compact="compact"
    data-test="compare-add-models"
    @open="showPickerModal"
  />
</template>
