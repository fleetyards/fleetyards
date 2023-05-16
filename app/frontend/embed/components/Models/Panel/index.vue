<template>
  <div>
    <Panel v-if="model" :class="`model-${model.slug}`">
      <div class="panel-heading">
        <h2 class="panel-title">
          <a :href="url" target="_blank" rel="noopener">
            {{ countLabel }}{{ model.name }}
          </a>
          <br />
          <small
            v-if="model.manufacturer"
            class="text-muted"
            v-html="model.manufacturer.name"
          />
        </h2>
      </div>
      <div
        :class="{
          'no-details': !details,
        }"
        class="panel-image text-center"
      >
        <LazyImage
          v-if="model.storeImageMedium"
          :href="url"
          target="_blank"
          rel="noopener"
          :aria-label="model.name"
          :src="model.storeImageMedium"
          :alt="model.name"
          class="image"
        />
      </div>
      <PanelDetails
        :key="`details-${model.slug}-${uuid}-wrapper`"
        :visible="details"
      >
        <div class="production-status">
          <strong class="text-uppercase">
            <template v-if="model.productionStatus">
              {{ t(`labels.model.productionStatus.${model.productionStatus}`) }}
            </template>
            <template v-else>
              {{ t(`labels.not-available`) }}
            </template>
          </strong>
        </div>
        <ModelTopMetrics :model="model" padding />
        <hr class="dark slim-spacer" />
        <ModelBaseMetrics :model="model" padding />
      </PanelDetails>
    </Panel>
  </div>
</template>

<script lang="ts" setup>
import Panel from "@/embed/components/Panel/index.vue";
import PanelDetails from "@/embed/components/Panel/PanelDetails/index.vue";
import ModelTopMetrics from "@/embed/components/Models/TopMetrics/index.vue";
import ModelBaseMetrics from "@/embed/components/Models/BaseMetrics/index.vue";
import LazyImage from "@/embed/components/LazyImage/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { v4 as uuidv4 } from "uuid";

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

const uuid = computed(() => uuidv4());

const url = computed(
  () => `${window.FRONTEND_ENDPOINT}/ships/${props.model.slug}`
);

const countLabel = computed(() => {
  if (!props.count) {
    return "";
  }
  return `${props.count}x `;
});
</script>

<script lang="ts">
export default {
  name: "ModelsPanel",
};
</script>
