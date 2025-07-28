<script lang="ts">
export default {
  name: "CompareModelsHeaderImage",
};
</script>

<script lang="ts" setup>
import { type Model } from "@/services/fyApi";
import { ViewImageSizeEnum } from "@/shared/components/ViewImage/types";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  model: Model;
};

defineProps<Props>();

const { t } = useI18n();

const { filter, filters } = useCompareModelFilters();

const remove = (model: Model) => {
  filter({
    models: (filters.value.models || []).filter((slug) => slug !== model.slug),
  });
};
</script>

<template>
  <div class="compare-image">
    <ViewImage
      v-if="model.media.storeImage"
      :image="model.media.storeImage"
      :size="ViewImageSizeEnum.LARGE"
      :alt="model.name"
    />
    <div
      v-tooltip="t('labels.compare.removeModel')"
      class="remove-model"
      @click="remove(model)"
    >
      <i class="fal fa-times" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
