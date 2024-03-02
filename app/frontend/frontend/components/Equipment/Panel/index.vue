<template>
  <Panel :bg-image="image" bg-rounded="top">
    <PanelHeading level="h2" shadow="top">
      {{ equipment.name }}
      <template v-if="equipment.itemTypeLabel" #subtitle>
        {{ equipment.itemTypeLabel }}
        <template v-if="equipment.slot">
          {{ equipment.slotLabel }}
        </template>
      </template>
      <template #actions>
        <AddToCartBtn
          :item="equipment"
          :type="SearchResultTypeEnum.EQUIPMENT"
          class="equipment-panel-add-to-cart-button"
        />
      </template>
    </PanelHeading>
    <template v-if="withStats" #footer>
      <div class="equipment-panel-footer">
        <MetricsList
          :metrics="metrics"
          class="equipment-panel-footer-metrics"
        />
        <template v-if="hasAvailability">
          <hr class="slim" />
          <ShopCommodityLocations
            :item="equipment"
            class="equipment-panel-footer-availability"
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
import { SearchResultTypeEnum } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import type { Equipment } from "@/services/fyApi";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";

const { t } = useI18n();

type Props = {
  equipment: Equipment;
  withStats?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withStats: true,
});
const hasAvailability = computed(() => {
  return (
    props.equipment.availability &&
    (props.equipment.availability.soldAt?.length ||
      props.equipment.availability.boughtAt?.length)
  );
});

const metrics = computed(() => {
  const data = [];

  if (props.equipment.manufacturer) {
    data.push({
      id: "manufacturer",
      label: t("commodityItem.manufacturer"),
      value: props.equipment.manufacturer?.name,
    });
  }

  if (props.equipment.grade) {
    data.push({
      id: "grade",
      label: t("commodityItem.grade"),
      value: props.equipment.grade,
    });
  }

  if (props.equipment.range) {
    data.push({
      id: "range",
      label: t("commodityItem.range"),
      value: props.equipment.range,
    });
  }

  if (props.equipment.rateOfFire) {
    data.push({
      id: "rateOfFire",
      label: t("commodityItem.rateOfFire"),
      value: props.equipment.rateOfFire,
    });
  }

  if (props.equipment.weaponClassLabel) {
    data.push({
      id: "weaponClassLabel",
      label: t("commodityItem.weaponClass"),
      value: props.equipment.weaponClassLabel,
    });
  }

  if (props.equipment.damageReduction) {
    data.push({
      id: "damageReduction",
      label: t("commodityItem.damageReduction"),
      value: props.equipment.damageReduction,
    });
  }

  if (props.equipment.storage) {
    data.push({
      id: "storage",
      label: t("commodityItem.storage"),
      value: props.equipment.storage,
    });
  }

  if (props.equipment.extras) {
    data.push({
      id: "extras",
      label: t("commodityItem.extras"),
      value: props.equipment.extras,
    });
  }

  return data;
});

const { supported: webpSupported } = useWebpCheck();

const image = computed(() => {
  if (props.equipment.media.storeImage) {
    return props.equipment.media.storeImage.medium;
  }
  if (props.equipment.manufacturer?.logo) {
    return props.equipment.manufacturer?.logo;
  }

  if (webpSupported) {
    return fallbackImage;
  }

  return fallbackImageJpg;
});
</script>

<script lang="ts">
export default {
  name: "EquipmentPanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
