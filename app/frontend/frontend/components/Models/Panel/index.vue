<template>
  <div>
    <Panel
      v-if="model"
      :id="model.slug"
      class="model-panel"
      :class="`model-panel-${model.slug}`"
    >
      <div class="panel-heading">
        <h2 class="panel-title">
          <router-link
            :to="{
              name: 'model',
              params: {
                slug: model.slug,
              },
            }"
          >
            <span>{{ model.name }}</span>
          </router-link>

          <br />

          <small>
            <router-link :to="manufacturerRoute">
              {{ manufacturerName }}
            </router-link>
          </small>

          <AddToHangar
            :model="model"
            class="panel-add-to-hangar-button"
            variant="panel"
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
          v-if="storeImage"
          :to="{ name: 'model', params: { slug: model.slug } }"
          :aria-label="model.name"
          :src="storeImage"
          :alt="model.name"
          class="image"
        >
          <div
            v-show="model.onSale"
            v-tooltip="t('labels.model.onSale')"
            class="on-sale"
          >
            <i class="fal fa-dollar-sign" />
          </div>
        </LazyImage>
      </div>
      <Collapsed
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
        <ModelPanelMetrics :model="model" />
      </Collapsed>
    </Panel>
  </div>
</template>

<script lang="ts" setup>
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import ModelPanelMetrics from "@/frontend/components/Models/PanelMetrics/index.vue";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/frontend/composables/useI18n";
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import { Model } from "@/services/fyApi";

type Props = {
  model: Model;
  details?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
});

const { t } = useI18n();

const uuid = ref<string>(uuidv4());

const storeImage = computed(() => props.model.media.storeImage?.medium);

onMounted(() => {
  uuid.value = uuidv4();
});

const manufacturerName = computed(() => {
  return props.model.manufacturer?.name;
});

const manufacturerRoute = computed(() => {
  return {
    query: {
      q: {
        manufacturerIn: [props.model.manufacturer?.slug],
      } as unknown as string,
    },
  };
});
</script>

<script lang="ts">
export default {
  name: "ModelPanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
