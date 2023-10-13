<template>
  <Panel
    :id="internalId"
    class="model-panel"
    :class="`model-panel-${model.slug}`"
    :highlight="highlight"
  >
    <div class="model-panel-inner">
      <div
        :key="internalStoreImage"
        v-lazy:background-image="internalStoreImage"
        class="model-panel-bg lazy"
        :class="{
          'model-panel-bg-rounded': !details,
        }"
      />
      <PanelHeading class="model-panel-heading">
        <h2 class="panel-title">
          <slot name="heading-title">
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

            <small v-if="model.manufacturer">
              <router-link
                :to="{
                  query: {
                    q: filterManufacturerQuery(
                      model.manufacturer,
                    ) as unknown as string,
                  },
                }"
              >
                {{ model.manufacturer.name }}
              </router-link>
            </small>
          </slot>
        </h2>

        <slot name="heading-actions">
          <AddToHangar
            :model="model"
            class="model-panel-add-to-hangar-button"
            variant="panel"
          />
        </slot>
      </PanelHeading>
      <PanelBody
        class="model-panel-body"
        :rounded="details ? undefined : 'bottom'"
      >
        <div
          v-show="model.onSale"
          v-tooltip="t('labels.model.onSale')"
          class="model-panel-on-sale"
        >
          <i class="fal fa-dollar-sign" />
        </div>
        <slot name="default" />
      </PanelBody>
    </div>

    <Collapsed
      :key="`details-${model.slug}-${internalId}-wrapper`"
      :visible="details"
    >
      <div class="model-panel-production-status">
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
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import ModelPanelMetrics from "@/frontend/components/Models/PanelMetrics/index.vue";
import type { Model, Manufacturer } from "@/services/fyApi";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  model: Model;
  details?: boolean;
  highlight?: boolean;
  id?: string;
  storeImage?: string;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
  highlight: false,
  id: undefined,
  storeImage: undefined,
});

const { t } = useI18n();

const internalStoreImage = computed(
  () => props.storeImage || props.model.media.storeImage?.medium,
);

const internalId = computed(() => props.id || props.model.id);

const filterManufacturerQuery = (manufacturer: Manufacturer) => ({
  manufacturerIn: [manufacturer],
});
</script>

<style lang="scss" scoped>
@import "index";
</style>
