<template>
  <Panel :bg-image="image" bg-rounded="top">
    <PanelHeading level="h2" shadow="top">
      {{ component.name }}
      <template v-if="component.itemTypeLabel" #subtitle>
        {{ component.itemTypeLabel }}
        <template v-if="component.manufacturer">
          {{ component.manufacturer.name }}
        </template>
      </template>
      <template #actions>
        <AddToCartBtn
          :item="component"
          :type="SearchResultTypeEnum.COMPONENT"
          class="component-panel-add-to-cart-button"
        />
      </template>
    </PanelHeading>
    <template v-if="withStats" #footer>
      <div class="component-panel-footer">
        <MetricsList
          :metrics="metrics"
          class="component-panel-footer-metrics"
        />
        <template v-if="hasAvailability">
          <hr class="slim" />
          <ShopCommodityLocations
            :item="component"
            class="component-panel-footer-availability"
          />
        </template>
      </div>
    </template>
  </Panel>
</template>

<script lang="ts" setup>
import ShopCommodityLocations from "@/frontend/components/ShopCommodities/Locations/index.vue";
import AddToCartBtn from "@/frontend/components/core/AppShoppingCart/AddToCartBtn/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import MetricsList from "@/shared/components/MetricsList/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import type { Component } from "@/services/fyApi";
import { SearchResultTypeEnum } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

const { t } = useI18n();

type Props = {
  component: Component;
  withStats?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withStats: true,
});

const hasAvailability = computed(() => {
  return (
    props.component.availability &&
    (props.component.availability.soldAt?.length ||
      props.component.availability.boughtAt?.length)
  );
});

const metrics = computed(() => {
  const data = [];

  if (props.component.size) {
    data.push({
      id: "size",
      label: t("commodityItem.size"),
      value: props.component.size,
    });
  }

  if (props.component.grade) {
    data.push({
      id: "grade",
      label: t("commodityItem.grade"),
      value: props.component.grade,
    });
  }

  if (props.component.typeLabel) {
    data.push({
      id: "typeLabel",
      label: t("commodityItem.type"),
      value: props.component.typeLabel,
    });
  }

  if (props.component.itemTypeLabel) {
    data.push({
      id: "itemTypeLabel",
      label: t("commodityItem.itemType"),
      value: props.component.itemTypeLabel,
    });
  }

  if (props.component.itemClassLabel) {
    data.push({
      id: "itemClassLabel",
      label: t("commodityItem.itemClass"),
      value: props.component.itemClassLabel,
    });
  }

  return data;
});

const { supported: webpSupported } = useWebpCheck();

const image = computed(() => {
  if (props.component.media.storeImage) {
    return props.component.media.storeImage.medium;
  }
  if (props.component.manufacturer?.logo) {
    return props.component.manufacturer?.logo;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<script lang="ts">
export default {
  name: "ComponentPanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
