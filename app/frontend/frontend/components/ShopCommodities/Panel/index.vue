<template>
  <Panel>
    <div class="teaser-panel">
      <LazyImage
        v-if="item.media.storeImage?.medium"
        :to="shopRoute"
        :src="item.media.storeImage?.medium"
        class="teaser-panel-image"
      />
      <div class="teaser-panel-body">
        <h3 v-tooltip="item.name">
          <router-link :to="shopRoute">
            {{ item.name }}
          </router-link>
        </h3>
        <ul v-if="showStats" class="list-unstyled">
          <li>
            <b>{{ t("commodityItem.location") }}:</b>
            <router-link :to="stationRoute">
              {{ item.shop.locationLabel }}
            </router-link>
          </li>
          <li>
            <b>{{ t("commodityItem.shop") }}:</b>
            <router-link :to="shopRoute">
              {{ item.shop.name }}
            </router-link>
          </li>
          <li v-if="item.item.grade">
            <b>{{ t("commodityItem.grade") }}:</b>
            {{ item.item.grade }}
          </li>
          <li v-if="item.item.size">
            <b>{{ t("commodityItem.size") }}:</b>
            {{ item.item.size }}
          </li>
          <li v-if="item.item.typeLabel">
            <b>{{ t("commodityItem.type") }}:</b>
            {{ item.item.typeLabel }}
          </li>
          <li v-if="item.item.slotLabel">
            <b>{{ t("commodityItem.slot") }}:</b>
            {{ item.item.slotLabel }}
          </li>
          <li v-if="item.item.itemTypeLabel">
            <b>{{ t("commodityItem.itemType") }}:</b>
            {{ item.item.itemTypeLabel }}
          </li>
          <li
            v-if="item.category === 'equipment' && item.item.weaponClassLabel"
          >
            <b>{{ t("commodityItem.weaponClass") }}:</b>
            {{ item.item.weaponClassLabel }}
          </li>
          <li v-else-if="item.item.itemClassLabel">
            <b>{{ t("commodityItem.itemClass") }}:</b>
            {{ item.item.itemClassLabel }}
          </li>
          <li v-if="item.category === 'equipment' && item.item.range">
            <b>{{ t("commodityItem.range") }}:</b>
            {{ toNumber(item.item.range, "distance") }}
          </li>
          <li v-if="item.category === 'equipment' && item.item.damageReduction">
            <b>{{ t("commodityItem.damageReduction") }}:</b>
            {{ toNumber(item.item.damageReduction, "percent") }}
          </li>
          <li v-if="item.category === 'equipment' && item.item.rateOfFire">
            <b>{{ t("commodityItem.rateOfFire") }}:</b>
            {{ toNumber(item.item.rateOfFire, "rateOfFire") }}
          </li>
          <li v-if="item.item.storage">
            <b>{{ t("commodityItem.storage") }}:</b>
            {{ item.item.storage }}
          </li>
        </ul>
        {{ item.item.extras }}
      </div>
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import type { ShopCommodityMinimal } from "@/services/fyApi";
import { useI18n } from "@/frontend/composables/useI18n";

const { t, toNumber } = useI18n();

type Props = {
  item: ShopCommodityMinimal;
};

const props = defineProps<Props>();

const showStats = computed(() => {
  return ["equipment", "component"].includes(props.item.category || "");
});

const shopRoute = computed(() => {
  return {
    name: "shop",
    params: {
      stationSlug: props.item.shop.station.slug,
      slug: props.item.shop.slug,
    },
  };
});

const stationRoute = computed(() => {
  return {
    name: "station",
    params: {
      slug: props.item.shop.station.slug,
    },
  };
});
</script>

<script lang="ts">
export default {
  name: "ShopCommodityPanel",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
