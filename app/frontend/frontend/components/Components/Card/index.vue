<script lang="ts">
export default {
  name: "ComponentCard",
};
</script>

<script lang="ts" setup>
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
import ItemCard from "@/shared/components/ItemCard/index.vue";
import CartAddToCart from "@/frontend/components/Cart/AddToCart/index.vue";
import {
  type ItemCardFacet,
  type ItemCardMaker,
} from "@/shared/components/ItemCard/types";
import { useComponentFacts } from "@/frontend/composables/useComponentFacts";
import { useAvailableComponentStats } from "@/frontend/composables/useComponentStats";
import { manufacturerMark } from "@/frontend/utils/manufacturerMark";
import { type Component, InventoryItemTypeEnum } from "@/services/fyApi";

type Props = {
  component: Component;
  details?: boolean;
};

const props = withDefaults(defineProps<Props>(), { details: false });

const route = useRoute();

// As in the row: a value the catalogue is narrowed by narrows it when clicked,
// and `page` is dropped because the result set it counted is gone.
const filterLink = (key: string, value: string) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const { categoryLabel, badges } = useComponentFacts(() => props.component);

const stats = useAvailableComponentStats(() => props.component);

const maker = computed<ItemCardMaker | undefined>(() => {
  const { manufacturer } = props.component;
  if (!manufacturer) return undefined;

  return {
    name: manufacturer.name,
    code: manufacturer.code || manufacturer.shortName || undefined,
    logo: manufacturerMark(manufacturer),
    to: manufacturer.slug
      ? filterLink("manufacturerSlugIn", manufacturer.slug)
      : undefined,
  };
});

const categories = computed<ItemCardFacet[]>(() => {
  const { category, subType } = props.component;
  const list: ItemCardFacet[] = [];

  if (category && categoryLabel.value) {
    list.push({
      key: "category",
      label: categoryLabel.value,
      to: filterLink("categoryIn", category),
    });
  }

  if (subType) {
    list.push({
      key: "subType",
      label: subType,
      to: filterLink("componentSubTypeIn", subType),
    });
  }

  return list;
});

const image = computed(
  () =>
    props.component.media.storeImage?.mediumUrl ||
    props.component.media.storeImage?.smallUrl,
);
</script>

<template>
  <ItemCard
    class="component-card"
    :data-test="`component-card-${component.slug || component.id}`"
    :to="
      component.slug
        ? { name: 'component', params: { slug: component.slug } }
        : undefined
    "
    :image="image"
    :maker="maker"
    :categories="categories"
    :badges="badges"
    :stats="details ? stats : []"
    :details="details"
  >
    <template #name>{{ component.name }}</template>

    <template #icon>
      <HardpointCategoryIcon :category="component.category" />
    </template>

    <template #actions>
      <CartAddToCart
        :item="{
          id: component.id,
          type: InventoryItemTypeEnum.COMPONENT,
          name: component.name,
        }"
      />
    </template>
  </ItemCard>
</template>
