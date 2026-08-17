<script lang="ts">
export default {
  name: "EmbedModelsPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import EmbedModelMetrics from "@/embed/components/Models/Metrics/index.vue";
import { useI18n } from "@/embed/composables/useI18n";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { PanelRoundedEnum } from "@/shared/components/base/Panel/types";
import fallbackImage from "@/images/fallback/store_image.jpg";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
  details?: boolean;
  count?: number;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
  count: undefined,
});

const { t } = useI18n();

const url = computed(
  () => `${window.FRONTEND_ENDPOINT}/ships/${props.model.slug}`,
);

const countLabel = computed(() => {
  if (!props.count) {
    return "";
  }
  return `${props.count}x `;
});

/*
 * Always an image, because the panel only opens its inner box - and with it the
 * 286px floor - when there is one to hold. The jpg rather than the webp the
 * frontend card prefers: the webp check runs in `frontend/App.vue` and never in
 * the embed, so `useWebpCheck` here would report an unverified `true`.
 */
const image = computed(
  () => props.model.media.storeImage?.mediumUrl || fallbackImage,
);
</script>

<template>
  <Panel
    v-if="model"
    class="embed-model-panel"
    :data-test="`model-${model.slug}`"
    :bg-image="image"
    :bg-rounded="details ? PanelRoundedEnum.TOP : PanelRoundedEnum.ALL"
  >
    <template #default>
      <PanelHeading shadow="top" :level="HeadingLevelEnum.H2">
        <template #default>
          <a :href="url" target="_blank" rel="noopener">
            {{ countLabel }}{{ model.name }}
          </a>
        </template>
        <template v-if="model.manufacturer" #subtitle>
          {{ model.manufacturer.name }}
        </template>
      </PanelHeading>
    </template>

    <template #footer>
      <Collapsed :key="`details-${model.slug}-wrapper`" :visible="details">
        <div class="embed-model-panel__production-status">
          <strong>
            <template v-if="model.productionStatus">
              {{ t(`model.productionStatuses.${model.productionStatus}`) }}
            </template>
            <template v-else>
              {{ t("model.productionStatuses.notAvailable") }}
            </template>
          </strong>
        </div>
        <EmbedModelMetrics :model="model" />
      </Collapsed>
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
// The same band the frontend card uses between photo and metrics, so the two
// surfaces read as one design rather than two generations of it.
.embed-model-panel__production-status {
  padding: 9px 16px;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  line-height: 1;
  text-transform: uppercase;
  color: $gray-light;
  background: rgba(#000, 0.12);
  border-bottom: 1px solid rgba($gray-light, 0.28);

  strong {
    font-weight: 500;
  }
}
</style>
