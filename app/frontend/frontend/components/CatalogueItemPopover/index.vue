<script lang="ts">
export default {
  name: "CatalogueItemPopover",
};
</script>

<script lang="ts" setup>
import BasePopover from "@/shared/components/Popover/index.vue";
import ComponentStatsCard from "@/frontend/components/StatsCard/Component/index.vue";
import EquipmentStatsCard from "@/frontend/components/StatsCard/Equipment/index.vue";
import CommodityStatsCard from "@/frontend/components/StatsCard/Commodity/index.vue";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";
import {
  useComponent as useComponentQuery,
  useEquipmentItem as useEquipmentItemQuery,
  useCommodity as useCommodityQuery,
  type Commodity,
  type Component,
  type Equipment,
} from "@/services/fyApi";
import { type CatalogueItemRef, type CatalogueRecord } from "./types";

type Props = {
  item: CatalogueItemRef;
  // The record itself, where the page already holds it -- a hardpoint row has
  // its component, a catalogue row its item. Without one the card is fetched.
  record?: CatalogueRecord;
  // Off where the trigger already sits inside a link to the same record, such
  // as a list row's name: an anchor inside an anchor does not work.
  link?: boolean;
  linkClass?: string;
  // For a trigger with no text of its own, such as an icon.
  linkLabel?: string;
  // Off for the same list-row name: the row's own link is the focus stop.
  focusable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  record: undefined,
  link: true,
  linkClass: undefined,
  linkLabel: undefined,
  focusable: true,
});

const route = computed(() => catalogueItemRoute(props.item));

const slug = computed(() => props.item.slug || "");

const isComponent = computed(() => props.item.type === "Component");
const isEquipment = computed(() => props.item.type === "Equipment");
const isCommodity = computed(() => props.item.type === "Commodity");

// Fetched the first time the card opens -- never for every link on a page --
// and left enabled afterwards, so the query cache (shared with the detail
// pages) answers every later open.
//
// The card only renders once it has opened, when its query is enabled, so
// `isPending` means the answer is still to come. A failed request leaves
// pending without data, which the card states rather than spinning on.
const requested = ref(false);

const fetches = (type: Ref<boolean>) =>
  computed(
    () => requested.value && type.value && !props.record && !!slug.value,
  );

const { data: fetchedComponent, isPending: componentPending } =
  useComponentQuery(slug, { query: { enabled: fetches(isComponent) } });

const { data: fetchedEquipment, isPending: equipmentPending } =
  useEquipmentItemQuery(slug, { query: { enabled: fetches(isEquipment) } });

const { data: fetchedCommodity, isPending: commodityPending } =
  useCommodityQuery(slug, { query: { enabled: fetches(isCommodity) } });

const component = computed(
  () => (props.record as Component | undefined) ?? fetchedComponent.value,
);
const equipment = computed(
  () => (props.record as Equipment | undefined) ?? fetchedEquipment.value,
);
const commodity = computed(
  () => (props.record as Commodity | undefined) ?? fetchedCommodity.value,
);

const pending = (type: Ref<boolean>, isPending: Ref<boolean>) =>
  computed(() => !props.record && type.value && isPending.value);

const componentLoading = pending(isComponent, componentPending);
const equipmentLoading = pending(isEquipment, equipmentPending);
const commodityLoading = pending(isCommodity, commodityPending);

// A record the catalogue does not list still has figures worth reading -- a
// door or a seat on a ship -- so a card needs a record or a page, not both.
const hasCard = computed(
  () =>
    (isComponent.value || isEquipment.value || isCommodity.value) &&
    (!!props.record || !!route.value),
);

const linked = computed(() => props.link && !!route.value);

const label = computed(() => props.item.name || props.linkLabel || "");
</script>

<template>
  <BasePopover
    v-if="hasCard"
    :label="label"
    :focusable="focusable"
    @open="requested = true"
  >
    <router-link
      v-if="linked"
      :to="route!"
      :class="linkClass"
      :aria-label="linkLabel"
      @click.stop
    >
      <slot>{{ item.name }}</slot>
    </router-link>
    <slot v-else>{{ item.name }}</slot>

    <template #content="{ close }">
      <ComponentStatsCard
        v-if="isComponent"
        compact
        :to="route ?? false"
        :name="label"
        :component="component"
        :loading="componentLoading"
        @navigate="close"
      />
      <EquipmentStatsCard
        v-else-if="isEquipment"
        compact
        :to="route ?? false"
        :name="label"
        :equipment="equipment"
        :loading="equipmentLoading"
        @navigate="close"
      />
      <CommodityStatsCard
        v-else
        compact
        :to="route ?? false"
        :name="label"
        :commodity="commodity"
        :loading="commodityLoading"
        @navigate="close"
      />
    </template>
  </BasePopover>

  <router-link
    v-else-if="linked"
    :to="route!"
    :class="linkClass"
    :aria-label="linkLabel"
    @click.stop
  >
    <slot>{{ item.name }}</slot>
  </router-link>

  <template v-else>
    <slot>{{ item.name }}</slot>
  </template>
</template>
