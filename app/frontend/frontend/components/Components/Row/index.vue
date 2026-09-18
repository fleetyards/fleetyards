<script lang="ts">
export default {
  name: "ComponentRow",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useComponentStats } from "@/frontend/composables/useComponentStats";
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";
import { type Component } from "@/services/fyApi";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t, tExists } = useI18n();

const icon = computed(() => categoryIcon(props.component.category));

const stats = useComponentStats(() => props.component);

// The one or two figures the renderer already marks as worth leading with --
// the same ones the detail page puts in its hero tiles. A row that repeated
// every metric would be the detail page.
//
// Filtered before it is sliced, so a component whose headline figure the build
// does not carry gives the slot to the next one it does rather than leading
// with "N/A": `toNumber` renders any falsy value as that string, and a column
// of them says nothing while taking the width of something that would.
const leadStats = computed(() => {
  const unavailable = t("labels.notAvailable");

  return stats.value
    .filter((s) => s.primary && s.value && s.value !== unavailable)
    .slice(0, 2);
});

const categoryLabel = computed(() => {
  const key = props.component.category;
  if (!key) return undefined;

  const path = `labels.hardpoint.categories.${key}`;

  return tExists(path) ? t(path) : key;
});
</script>

<template>
  <!-- A component with no name has no slug either -- the slug is built from the
       name -- and `router-link` throws on a missing required param rather than
       rendering nothing, which took the whole list down with it. Such a row has
       no detail page to reach, so it is not a link. The catalogue filters these
       out upstream; this is the guard that keeps one reaching the page from
       being fatal. -->
  <component
    :is="component.slug ? 'router-link' : 'span'"
    class="component-row"
    :class="{ 'component-row--unlinked': !component.slug }"
    :to="
      component.slug
        ? { name: 'component', params: { slug: component.slug } }
        : undefined
    "
  >
    <img
      v-if="icon?.kind === 'svg'"
      :src="icon.src"
      class="component-row__icon"
      alt=""
    />
    <span
      v-else-if="icon?.kind === 'fa'"
      class="component-row__icon component-row__icon--glyph"
    >
      <i :class="icon.className" />
    </span>
    <span v-else class="component-row__icon" />

    <span class="component-row__main">
      <span class="component-row__name">{{ component.name }}</span>
      <span class="component-row__sub">
        <span v-if="component.manufacturer">
          {{ component.manufacturer.name }}
        </span>
        <span v-if="categoryLabel">{{ categoryLabel }}</span>
      </span>
    </span>

    <span class="component-row__stats">
      <span
        v-for="stat in leadStats"
        :key="stat.label"
        class="component-row__stat"
      >
        <span class="component-row__stat-label">{{ stat.label }}</span>
        <span class="component-row__stat-value">{{ stat.value }}</span>
      </span>
    </span>

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
        <span class="component-row__badge-value">{{
          component.gradeLabel
        }}</span>
      </span>
    </span>
  </component>
</template>

<style lang="scss" scoped>
@import "index";
</style>
