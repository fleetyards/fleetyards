<script lang="ts">
export default {
  name: "ComponentRow",
};
</script>

<script lang="ts" setup>
import ComponentCategoryIcon from "@/frontend/components/Components/CategoryIcon/index.vue";
import ComponentLeadMetric from "@/frontend/components/Components/LeadMetric/index.vue";
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
</script>

<template>
  <!-- A container, not one big link. The row holds links of its own now -- the
       manufacturer and the category each narrow the catalogue -- and an anchor
       inside an anchor is invalid and does not work. The name is the way to the
       component instead.

       It has no link at all when there is no slug: a component the game never
       named never got one, `router-link` throws on a missing required param
       rather than rendering nothing, and that took the whole list down. The
       catalogue filters those out upstream; this is the guard for one that
       reaches the page anyway. -->
  <div class="component-row">
    <ComponentCategoryIcon :category="component.category" />

    <span class="component-row__main">
      <router-link
        v-if="component.slug"
        class="component-row__name"
        :to="{ name: 'component', params: { slug: component.slug } }"
      >
        {{ component.name }}
      </router-link>
      <span v-else class="component-row__name">{{ component.name }}</span>

      <span class="component-row__sub">
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
      </span>
    </span>

    <ComponentLeadMetric :component="component" />

    <!-- Labelled, because a row has no column heading above it to say which
         figure a bare "1" or "A" is. -->
    <span class="component-row__badges">
      <span v-if="component.size" class="component-row__badge">
        <span class="component-row__badge-label">
          {{ t("labels.hardpoint.size") }}
        </span>
        <span class="component-row__badge-value">{{ component.size }}</span>
      </span>
      <span v-if="component.gradeLabel" class="component-row__badge">
        <span class="component-row__badge-label">
          {{ t("labels.component.grade") }}
        </span>
        <span class="component-row__badge-value">
          {{ component.gradeLabel }}
        </span>
      </span>
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
