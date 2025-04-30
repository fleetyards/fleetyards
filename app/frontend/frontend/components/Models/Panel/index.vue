<script lang="ts">
export default {
  name: "ModelPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import AddToHangar from "@/frontend/components/Models/AddToHangar/index.vue";
import ModelPanelMetrics from "@/frontend/components/Models/PanelMetrics/index.vue";
import type { Model, Manufacturer } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  PanelShadowsEnum,
  PanelBgRoundedEnum,
} from "@/shared/components/base/Panel/types";

type Props = {
  model: Model;
  details?: boolean;
  highlight?: boolean;
  id?: string;
  storeImage?: string;
  level?: HeadingLevelEnum;
};

const props = withDefaults(defineProps<Props>(), {
  details: false,
  highlight: false,
  id: undefined,
  storeImage: undefined,
  level: HeadingLevelEnum.H2,
});

const { t } = useI18n();

const internalId = computed(() => props.id || props.model.id);

const filterManufacturerQuery = (manufacturer: Manufacturer) => ({
  manufacturerIn: [manufacturer],
});

const { supported: webpSupported } = useWebpCheck();

const image = computed(() => {
  if (props.storeImage) {
    return props.storeImage;
  }

  if (props.model.media.storeImage) {
    return props.model.media.storeImage.mediumUrl;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<template>
  <Panel
    :id="internalId"
    class="model-panel"
    :class="`model-panel-${model.slug}`"
    :highlight="highlight"
    :bg-image="image"
    :bg-rounded="details ? PanelBgRoundedEnum.TOP : PanelBgRoundedEnum.ALL"
    :shadow="PanelShadowsEnum.TOP"
  >
    <template #default>
      <PanelHeading :level="level" class="model-panel-heading">
        <template #default>
          <slot name="heading-title">
            <router-link
              :to="{
                name: 'ship',
                params: {
                  slug: model.slug,
                },
              }"
            >
              <span>{{ model.name }}</span>
            </router-link>
          </slot>
        </template>
        <template #subtitle>
          <slot v-if="model.manufacturer" name="heading-subtitle">
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
          </slot>
        </template>
        <template #actions>
          <slot name="heading-actions">
            <AddToHangar
              :model="model"
              class="model-panel--add-to-hangar-button"
              variant="panel"
            />
          </slot>
        </template>
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
    </template>

    <template #footer>
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
    </template>
  </Panel>
</template>

<style lang="scss" scoped>
@import "index";
</style>
