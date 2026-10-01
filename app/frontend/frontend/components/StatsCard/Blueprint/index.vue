<script lang="ts">
export default {
  name: "BlueprintStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";
import { useCraftTime } from "@/frontend/composables/useCraftTime";
import { useI18n } from "@/shared/composables/useI18n";
import { type Blueprint } from "@/services/fyApi";

type Props = {
  blueprint?: Blueprint;
  name?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  blueprint: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();
const { format: formatCraftTime } = useCraftTime();

const stats = computed<HardpointStat[]>(() => {
  const blueprint = props.blueprint;
  if (!blueprint) return [];

  const craftTime = formatCraftTime(blueprint.craftTime);

  return [
    blueprint.craftable?.name
      ? {
          label: t("labels.blueprint.makesA"),
          value: blueprint.craftable.name,
          wide: true,
        }
      : undefined,
    craftTime
      ? { label: t("labels.blueprint.craftTime"), value: craftTime }
      : undefined,
    blueprint.slotCount
      ? {
          label: t("labels.blueprint.slots"),
          value: String(blueprint.slotCount),
        }
      : undefined,
  ].filter((stat): stat is HardpointStat => !!stat);
});

const subtitle = computed(
  () =>
    [
      props.blueprint?.craftable?.type
        ? t(`labels.blueprint.craftableTypes.${props.blueprint.craftable.type}`)
        : undefined,
      props.blueprint?.retired ? t("labels.blueprint.retired") : undefined,
    ]
      .filter(Boolean)
      .join(" · ") || undefined,
);

const ownRoute = computed(() =>
  props.blueprint?.slug
    ? { name: "blueprint", params: { slug: props.blueprint.slug } }
    : undefined,
);
</script>

<template>
  <StatsCard
    compact
    :title="blueprint?.name || name || ''"
    variant="slim"
    :subtitle="subtitle"
    :stats="stats"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :loading="loading"
    :unavailable="!loading && !blueprint"
    @navigate="emit('navigate')"
  />
</template>
