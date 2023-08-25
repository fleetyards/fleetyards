<template>
  <Panel>
    <div class="teaser-panel item-panel">
      <LazyImage v-if="image" :src="image" class="teaser-panel-image" />
      <div class="teaser-panel-body">
        <h2 v-tooltip="equipment.name">
          {{ equipment.name }}
          <small v-if="equipment.typeLabel">
            <br />
            {{ equipment.itemTypeLabel }}
            <template v-if="equipment.slot">
              {{ equipment.slotLabel }}
            </template>
          </small>
        </h2>
        <AddToCartBtn
          :item="equipment"
          :type="SearchResultTypeEnum.EQUIPMENT"
        />
        <div class="metrics-list">
          <div v-if="equipment.manufacturer" class="metrics-item">
            <div class="metrics-label">
              {{ t("commodityItem.manufacturer") }}:
            </div>
            <div class="metrics-value" v-html="equipment.manufacturer.name" />
          </div>
          <div v-if="equipment.size" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.size") }}:</div>
            <div class="metrics-value">
              {{ equipment.size }}
            </div>
          </div>
          <div v-if="equipment.grade" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.grade") }}:</div>
            <div class="metrics-value">
              {{ equipment.grade }}
            </div>
          </div>
          <div v-if="equipment.range" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.range") }}:</div>
            <div class="metrics-value">
              {{ equipment.range }}
            </div>
          </div>
          <div v-if="equipment.rateOfFire" class="metrics-item">
            <div class="metrics-label">
              {{ t("commodityItem.rateOfFire") }}:
            </div>
            <div class="metrics-value">
              {{ equipment.rateOfFire }}
            </div>
          </div>
          <div v-if="equipment.weaponClassLabel" class="metrics-item">
            <div class="metrics-label">
              {{ t("commodityItem.weaponClass") }}:
            </div>
            <div class="metrics-value">
              {{ equipment.weaponClassLabel }}
            </div>
          </div>
          <div v-if="equipment.damageReduction" class="metrics-item">
            <div class="metrics-label">
              {{ t("commodityItem.damageReduction") }}:
            </div>
            <div class="metrics-value">
              {{ equipment.damageReduction }}
            </div>
          </div>
          <div v-if="equipment.storage" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.storage") }}:</div>
            <div class="metrics-value">
              {{ equipment.storage }}
            </div>
          </div>
          <div v-if="equipment.extras" class="metrics-item">
            <div class="metrics-label">{{ t("commodityItem.extras") }}:</div>
            <div class="metrics-value">
              {{ equipment.extras }}
            </div>
          </div>
        </div>
        <hr class="slim" />
        <ShopCommodityLocations :item="equipment" />
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import ShopCommodityLocations from "@/frontend/components/ShopCommodities/Locations/index.vue";
import AddToCartBtn from "@/frontend/core/components/AppShoppingCart/AddToCartBtn/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { SearchResultTypeEnum } from "@/services/fyApi";
import { useI18n } from "@/frontend/composables/useI18n";
import type { Equipment } from "@/services/fyApi";

const { t } = useI18n();

type Props = {
  equipment: Equipment;
  showStats?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  showStats: true,
});

const image = computed(() => {
  if (!props.equipment.media.storeImage) {
    return props.equipment.manufacturer?.logo;
  }

  return props.equipment.storeImage;
});
</script>

<script lang="ts">
export default {
  name: "EquipmentPanel",
};
</script>
