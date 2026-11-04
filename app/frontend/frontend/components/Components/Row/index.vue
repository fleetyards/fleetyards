<script lang="ts">
export default {
  name: "ComponentRow",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import ComponentLeadMetric from "@/frontend/components/Components/LeadMetric/index.vue";
import { manufacturerMark } from "@/frontend/utils/manufacturerMark";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import CartAddToCart from "@/frontend/components/Cart/AddToCart/index.vue";
import { useComponentFacts } from "@/frontend/composables/useComponentFacts";
import { type Component, InventoryItemTypeEnum } from "@/services/fyApi";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const route = useRoute();

// Every value the catalogue can be narrowed by is a link that narrows it. The
// filters live in the route query rather than in a store, so this is a plain
// link: shareable, undone by the back button, and read back by the filter form.
//
// `page` is dropped -- the row that was clicked is almost never on the same
// page of a different, smaller result set.
const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const { categoryLabel, badges } = useComponentFacts(() => props.component);

const manufacturerLogo = computed(() =>
  manufacturerMark(props.component.manufacturer),
);
</script>

<template>
  <RowListItem
    class="component-row"
    :to="
      component.slug
        ? { name: 'component', params: { slug: component.slug } }
        : undefined
    "
    :badges="badges"
  >
    <template #leading>
      <span class="component-row__thumb">
        <img
          v-if="component.media.storeImage?.smallUrl"
          class="component-row__image"
          :src="component.media.storeImage.smallUrl"
          alt=""
          loading="lazy"
          data-test="component-row-image"
        />
        <HardpointCategoryIcon
          v-else
          :category="component.category"
          class="component-row__icon"
        />
      </span>
    </template>

    <!-- The name is already the row's link, so it opens the card without
         a second link or focus stop of its own. -->
    <template #name>
      <CatalogueItemPopover
        :item="{
          type: 'Component',
          slug: component.slug,
          name: component.name,
        }"
        :record="component"
        :link="false"
        :focusable="false"
      >
        {{ component.name }}
      </CatalogueItemPopover>
    </template>

    <template #sub>
      <router-link
        v-if="component.manufacturer?.slug"
        :to="filterLink('manufacturerSlugIn', component.manufacturer.slug)"
      >
        <img
          v-if="manufacturerLogo"
          class="component-row__maker-logo"
          :src="manufacturerLogo"
          alt=""
          loading="lazy"
          data-test="component-row-maker-logo"
        />
        {{ component.manufacturer.name }}
      </router-link>
      <router-link
        v-if="component.category"
        :to="filterLink('categoryIn', component.category)"
      >
        {{ categoryLabel }}
      </router-link>
      <router-link
        v-if="component.subType"
        :to="filterLink('componentSubTypeIn', component.subType)"
      >
        {{ component.subType }}
      </router-link>
    </template>

    <ComponentLeadMetric :component="component" />

    <template #actions>
      <CartAddToCart
        :item="{
          id: component.id,
          type: InventoryItemTypeEnum.COMPONENT,
          name: component.name,
        }"
        variant="row"
      />
    </template>
  </RowListItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
