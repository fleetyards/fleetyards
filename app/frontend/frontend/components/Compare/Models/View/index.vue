<script lang="ts">
export default {
  name: "ModelsCompareView",
};
</script>

<script lang="ts" setup>
import CompareSection from "@/frontend/components/Compare/Models/Section/index.vue";
import CompareContentRow from "@/frontend/components/Compare/Models/ContentRow/index.vue";
import FleetchartItemImage from "@/frontend/components/Fleetchart/List/Item/Image/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const maxLength = computed(() =>
  Math.max(
    ...props.models.map((model) => model.metrics.fleetchartOffsetLength || 1),
    0,
  ),
);

// Every silhouette is scaled against the longest ship on screen, so the columns
// read as a size comparison rather than a row of thumbnails.
const relativeLength = (model: Model) =>
  ((model.metrics.fleetchartOffsetLength || 1) * 100) / maxLength.value;

const hasData = computed(() =>
  props.models.some(
    (model) => model.media.sideView?.smallUrl || model.media.topView?.smallUrl,
  ),
);
</script>

<template>
  <CompareSection
    v-if="hasData"
    id="compare-views"
    :title="t('labels.metrics.views')"
  >
    <CompareContentRow :models="models" :label="t('labels.model.sideView')">
      <template #default="{ model }">
        <FleetchartItemImage
          v-if="model.media.sideView?.smallUrl"
          :label="model.name"
          :src="model.media.sideView?.smallUrl"
          :max-width="`${relativeLength(model)}%`"
        />
      </template>
    </CompareContentRow>
    <CompareContentRow :models="models" :label="t('labels.model.topView')">
      <template #default="{ model }">
        <FleetchartItemImage
          v-if="model.media.topView?.smallUrl"
          :label="model.name"
          :src="model.media.topView?.smallUrl"
          :max-width="`${relativeLength(model)}%`"
        />
      </template>
    </CompareContentRow>
  </CompareSection>
</template>
