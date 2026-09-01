<script lang="ts">
export default {
  name: "CompareModelsForm",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { MAX_MODELS } from "@/frontend/components/Compare/constants";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const comlink = useComlink();

const { filters } = useCompareModelFilters();

const full = computed(() => filters.value.models.length >= MAX_MODELS);

const tooltip = computed(() =>
  full.value ? t("labels.compare.enough") : undefined,
);

const showPickerModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Compare/Models/PickerModal/index.vue"),
    wide: true,
  });
};
</script>

<template>
  <!-- The tooltip hangs on the wrapper, not the button: a disabled button
       dispatches no pointer events, so the one case that has something to say is
       the one that could never say it. -->
  <div v-tooltip="tooltip" class="compare-form">
    <Btn
      :disabled="full"
      :size="BtnSizesEnum.MD"
      data-test="compare-add-models"
      @click="showPickerModal"
    >
      <i class="fa-light fa-plus" />
      {{ t("labels.compare.selectShips") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
