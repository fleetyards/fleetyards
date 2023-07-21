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
          v-if="model.media.storeImage?.medium"
          :href="url"
          target="_blank"
          rel="noopener"
          :aria-label="model.name"
          :src="model.media.storeImage.medium"
          :alt="model.name"
          class="image"
        />
      </div>
      <Collapsed
        :key="`details-${model.slug}-${uuid}-wrapper`"
        :visible="details"
      >
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
        <ModelTopMetrics :model="model" padding />
        <hr class="dark slim-spacer" />
        <ModelBaseMetrics :model="model" padding />
      </Collapsed>
    </Panel>
  </div>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import ModelTopMetrics from "@/embed/components/Models/TopMetrics/index.vue";
import ModelBaseMetrics from "@/embed/components/Models/BaseMetrics/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { useI18n } from "@/embed/composables/useI18n";
import { v4 as uuidv4 } from "uuid";
import type { ModelMinimal } from "@/services/fyApi";

type Props = {
  model: ModelMinimal;
  details?: boolean;
  count?: number;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
  count: undefined,
});

const { t } = useI18n();

const uuid = ref<string>(uuidv4());

const url = computed(
  () => `${window.FRONTEND_ENDPOINT}/ships/${props.model.slug}`
);

const countLabel = computed(() => {
  if (!props.count) {
    return "";
  }
  return `${props.count}x `;
});

onMounted(() => {
  uuid.value = uuidv4();
});
</script>

<script lang="ts">
export default {
  name: "ModelsPanel",
};
</script>
