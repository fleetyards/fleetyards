<template>
  <Panel v-if="item" :id="`${item.resultType}-${item.id}`">
    <div class="panel-heading">
      <h2 class="panel-title">
        <router-link :to="route">
          {{ item.name }}
        </router-link>

        <br />

        <small class="text-muted">
          {{ item.locationLabel }}
        </small>
      </h2>
    </div>
    <div class="panel-image text-center">
      <LazyImage
        v-if="item.media.storeImage?.medium"
        :to="route"
        :aria-label="item.name"
        :src="item.media.storeImage?.medium"
        :alt="item.name"
        class="image"
      />
    </div>
  </Panel>
</template>

<script lang="ts" setup>
import Panel from "@/shared/components/Panel/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import type {
  ModelMinimal,
  CommodityMinimal,
  EquipmentMinimal,
  ShopMinimal,
  StationMinimal,
} from "@/services/fyApi";

type SearchResult = (
  | ModelMinimal
  | CommodityMinimal
  | EquipmentMinimal
  | ShopMinimal
  | StationMinimal
) & { resultType: "shop" | "station" };

type Props = {
  item: SearchResult;
};

const props = defineProps<Props>();

const route = computed(() => {
  switch (props.item.resultType) {
    case "shop":
      return {
        name: "shop",
        params: {
          stationSlug: (props.item as ShopMinimal).station.slug,
          slug: props.item.slug,
        },
      };
    case "station":
      return { name: "station", params: { slug: props.item.slug } };
    default:
      return "";
  }
});
</script>

<script lang="ts">
export default {
  name: "SearchPanel",
};
</script>
