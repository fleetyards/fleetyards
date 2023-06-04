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
            <router-link
              :to="{
                query: {
                  q: filterManufacturerQuery(model.manufacturer.slug),
                },
              }"
              v-html="model.manufacturer.name"
            />
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
        <ModelPanelMetrics :model="model" />
      </PanelDetails>
    </Panel>
  </div>
</template>

<script lang="ts" setup>
import Panel from "@/frontend/core/components/Panel/index.vue";
import PanelDetails from "@/frontend/core/components/Panel/PanelDetails/index.vue";
import LazyImage from "@/frontend/core/components/LazyImage/index.vue";
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import ModelPanelMetrics from "@/frontend/components/Models/PanelMetrics/index.vue";
import { v4 as uuidv4 } from "uuid";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  model: Model;
  details?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
});

const { t } = useI18n();

const uuid = uuidv4();

const storeImage = computed(() => props.model.media.storeImage?.medium);

const filterManufacturerQuery = (manufacturer: string) => ({
  manufacturerIn: [manufacturer],
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
