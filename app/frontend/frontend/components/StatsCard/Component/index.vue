<script lang="ts">
export default {
  name: "ComponentStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import { type StatsCardBadge } from "@/frontend/components/StatsCard/types";
import { useComponentStats } from "@/frontend/composables/useComponentStats";
import { useI18n } from "@/shared/composables/useI18n";
import { type Component } from "@/services/fyApi";

type Props = {
  component?: Component;
  compact?: boolean;
  // What the card is titled while its record is missing, since a compact card
  // otherwise takes its title from the record.
  name?: string;
  // Where the card's detail link goes, when the caller knows better than the
  // record -- a reference can say the catalogue does not list it. `false`
  // drops the link.
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  component: undefined,
  compact: false,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t, tExists } = useI18n();

const allStats = useComponentStats(() => props.component);

// On the detail page a mode of the item gets a card of its own beside this
// one; floating over a list, the card is all there is, so it keeps them.
const stats = computed(() =>
  props.compact ? allStats.value : allStats.value.filter((stat) => !stat.group),
);

const categoryLabel = computed(() => {
  const key = props.component?.category;
  if (!key) return undefined;

  const path = `labels.hardpoint.categories.${key}`;

  return tExists(path) ? t(path) : key;
});

const badges = computed<StatsCardBadge[]>(() => {
  const component = props.component;
  if (!component) return [];

  const list: StatsCardBadge[] = [];

  if (component.size) {
    list.push({
      key: "size",
      label: t("labels.hardpoint.size"),
      value: String(component.size),
    });
  }

  if (component.gradeLabel) {
    list.push({
      key: "grade",
      label: t("labels.component.grade"),
      value: component.gradeLabel,
    });
  }

  if (component.itemClassLabel) {
    list.push({
      key: "class",
      label: t("labels.component.itemClass"),
      value: component.itemClassLabel,
    });
  }

  return list;
});

// Components the catalogue does not list -- doors, controllers, seats -- have
// no page to send anyone to.
const ownRoute = computed(() =>
  props.component?.slug && props.component.catalogued !== false
    ? { name: "component", params: { slug: props.component.slug } }
    : undefined,
);
</script>

<template>
  <StatsCard
    :compact="compact"
    :title="
      compact ? component?.name || name || '' : t('headlines.component.metrics')
    "
    kind="Component"
    :category="categoryLabel"
    :subtitle="component?.manufacturer?.name || undefined"
    :badges="badges"
    :stats="stats"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :empty-text="t('labels.component.noMetrics')"
    :loading="loading"
    :unavailable="compact && !loading && !component"
    @navigate="emit('navigate')"
  >
    <template v-if="$slots.default" #default>
      <slot />
    </template>
  </StatsCard>
</template>
