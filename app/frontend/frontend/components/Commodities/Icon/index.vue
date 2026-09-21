<script lang="ts">
export default {
  name: "CommodityIcon",
};
</script>

<script lang="ts" setup>
import { type Commodity } from "@/services/fyApi";

type Props = {
  commodity: Commodity;
};

const props = defineProps<Props>();

// The export ships an inventory icon for 63 of the 232, and they are SVG rather
// than artwork — a glyph at row scale, not a picture. So where one exists it is
// the leading mark, and where none does the type answers instead. A placeholder
// box would leave whole categories (nothing `manmade` carries an icon, nor
// anything `nonmetals`) as a column of empty squares.
const TYPE_ICONS: Record<string, string> = {
  agricultural_supply: "fa-wheat-awn",
  alloy: "fa-layer-group",
  consumer_goods: "fa-bag-shopping",
  drink: "fa-wine-bottle",
  food: "fa-utensils",
  gas: "fa-cloud",
  hpmc: "fa-cube",
  manmade: "fa-gear",
  medical_supply: "fa-briefcase-medical",
  metal: "fa-cubes",
  military_supply: "fa-shield",
  mineral: "fa-gem",
  natural: "fa-leaf",
  nonmetals: "fa-atom",
  plasma_fuel: "fa-bolt",
  processed_goods: "fa-boxes-stacked",
  quantum_fuel: "fa-atom-simple",
  rmc: "fa-recycle",
  scrap: "fa-screwdriver-wrench",
  vice: "fa-pills",
  waste: "fa-dumpster",
};

const image = computed(() => props.commodity.storeImage?.smallUrl);

// A type a later patch introduces lands on the generic crate rather than on
// nothing, which would misalign the rest of the row.
const glyph = computed(
  () => TYPE_ICONS[props.commodity.commodityType ?? ""] ?? "fa-box",
);
</script>

<template>
  <img
    v-if="image"
    :src="image"
    class="commodity-icon"
    alt=""
    loading="lazy"
    width="24"
    height="24"
  />
  <span v-else class="commodity-icon commodity-icon--glyph">
    <i :class="['fa-duotone', glyph]" />
  </span>
</template>

<style lang="scss" scoped>
.commodity-icon {
  width: 24px;
  height: 24px;
  flex: none;

  &--glyph {
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    line-height: 1;
    color: var(--color-primary, #428bca);
  }
}
</style>
