<script lang="ts">
export default {
  name: "ComponentRow",
};
</script>

<script lang="ts" setup>
import ComponentCategoryIcon from "@/frontend/components/Components/CategoryIcon/index.vue";
import ComponentLeadMetric from "@/frontend/components/Components/LeadMetric/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import { type RowListItemBadge } from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Component } from "@/services/fyApi";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t, tExists } = useI18n();

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

// The payload carries the game's own category string ("quantumdrive"). The
// hardpoint list already names all of them in every locale, so the label comes
// from there rather than a second vocabulary -- falling back to the raw key for
// a category a patch introduces before anyone writes a label for it.
const categoryLabel = computed(() => {
  const key = props.component.category;
  if (!key) return undefined;

  const path = `labels.hardpoint.categories.${key}`;

  return tExists(path) ? t(path) : key;
});

const badges = computed<RowListItemBadge[]>(() => {
  const list: RowListItemBadge[] = [];

  if (props.component.size) {
    list.push({
      key: "size",
      label: t("labels.hardpoint.size"),
      value: String(props.component.size),
    });
  }

  if (props.component.gradeLabel) {
    list.push({
      key: "grade",
      label: t("labels.component.grade"),
      value: props.component.gradeLabel,
    });
  }

  return list;
});
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
      <ComponentCategoryIcon :category="component.category" />
    </template>

    <template #name>{{ component.name }}</template>

    <template #sub>
      <router-link
        v-if="component.manufacturer?.slug"
        :to="filterLink('manufacturerSlugIn', component.manufacturer.slug)"
      >
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
  </RowListItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
