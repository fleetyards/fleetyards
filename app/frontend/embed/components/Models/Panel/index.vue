<script lang="ts">
export default {
  name: "EmbedModelsPanel",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import EmbedModelMetrics from "@/embed/components/Models/Metrics/index.vue";
import { useI18n } from "@/embed/composables/useI18n";
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

const image = computed(() => props.model.media.storeImage?.mediumUrl || null);
</script>

<template>
  <div
    v-if="model"
    class="panel-wrapper panel-outer-spacing"
    :data-test="`model-${model.slug}`"
  >
    <div class="panel">
      <div class="panel-inner" :class="{ 'panel-inner--details': details }">
        <div
          v-if="image"
          class="embed-panel-bg"
          :class="{ 'embed-panel-bg--rounded-top': details }"
          :style="{ backgroundImage: `url(${image})` }"
        />
        <div v-if="image" class="embed-panel-shadow" />
        <div class="panel-heading">
          <h2 class="panel-title">
            <a :href="url" target="_blank" rel="noopener">
              {{ countLabel }}{{ model.name }}
            </a>
            <br />
            <small v-if="model.manufacturer" class="text-muted">
              {{ model.manufacturer.name }}
            </small>
          </h2>
        </div>
      </div>
      <Collapsed :key="`details-${model.slug}-wrapper`" :visible="details">
        <div class="production-status">
          <strong class="text-uppercase">
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
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/stylesheets/variables";

.embed-panel-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
  border-radius: $panelContentBorderRadius;

  &--rounded-top {
    border-bottom-left-radius: 0;
    border-bottom-right-radius: 0;
  }
}

.panel-inner {
  position: relative;
  display: flex;
  flex-direction: column;
  min-height: 286px;
  border-radius: $panelContentBorderRadius;
}

.embed-panel-shadow {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 60%;
  background: linear-gradient(to top, rgba(0, 0, 0, 0.8) 0%, transparent 100%);
  border-radius: $panelContentBorderRadius;
  pointer-events: none;
}

.panel-inner.panel-inner--details {
  .embed-panel-shadow {
    border-bottom-left-radius: 0;
    border-bottom-right-radius: 0;
  }
}

.panel-heading {
  margin-top: auto;
  position: relative;
  z-index: 1;
}
</style>
