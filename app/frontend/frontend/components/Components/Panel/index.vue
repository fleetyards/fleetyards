<template>
  <Panel>
    <div class="teaser-panel item-panel">
      <LazyImage v-if="image" :src="image" class="teaser-panel-image" />
      <div class="teaser-panel-body">
        <h2 v-tooltip="component.name">
          {{ component.name }}
          <small v-if="component.manufacturer">
            <br />
            <span v-html="component.manufacturer.name" />
          </small>
        </h2>
        <AddToCartBtn
          :item="component"
          :type="SearchResultTypeEnum.COMPONENT"
          class="add-to-cart"
        />
        <div v-if="showMetrics" class="metrics-list">
          <div v-if="component.size" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.size") }}:</div>
            <div class="metrics-value">
              {{ component.size }}
            </div>
          </div>
          <div v-if="component.grade" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.grade") }}:</div>
            <div class="metrics-value">
              {{ component.grade }}
            </div>
          </div>
          <div v-if="component.typeLabel" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.type") }}:</div>
            <div class="metrics-value">
              {{ component.typeLabel }}
            </div>
          </div>
          <div v-if="component.itemTypeLabel" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.itemType") }}:</div>
            <div class="metrics-value">
              {{ component.itemTypeLabel }}
            </div>
          </div>
          <div v-if="component.itemClassLabel" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.itemClass") }}:</div>
            <div class="metrics-value">
              {{ component.itemClassLabel }}
            </div>
          </div>
        </div>
        <hr class="slim" />
        <ShopCommodityLocations :item="component" />
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import AddToCartBtn from "@/frontend/components/core/AppShoppingCart/AddToCartBtn/index.vue";
import ShopCommodityLocations from "@/frontend/components/ShopCommodities/Locations/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import type { Component } from "@/services/fyApi";
import { SearchResultTypeEnum } from "@/services/fyApi";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

type Props = {
  component: Component;
  showMetrics?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showMetrics: true,
});

const image = computed(() => {
  if (!props.component.media.storeImage) {
    return props.component.manufacturer?.logo;
  }

  return props.component.media.storeImage.large;
});
</script>

<script lang="ts">
export default {
  name: "ComponentPanel",
};
</script>
