<script lang="ts">
export default {
  name: "ShipStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";
import { useI18n } from "@/shared/composables/useI18n";
import { type Model } from "@/services/fyApi";

type Props = {
  model?: Model;
  // What the card is titled while its record is missing.
  name?: string;
  // `false` drops the detail link.
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  model: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();

const stats = computed<HardpointStat[]>(() => {
  const model = props.model;
  if (!model) return [];

  const crew = [model.crew.minLabel, model.crew.maxLabel].filter(Boolean);

  return [
    {
      label: t("labels.model.manufacturer"),
      value: model.manufacturer.name,
      wide: true,
    },
    crew.length
      ? { label: t("labels.model.minCrew"), value: crew.join(" – ") }
      : undefined,
    model.pledgePriceLabel
      ? { label: t("labels.model.pledgePrice"), value: model.pledgePriceLabel }
      : undefined,
    model.productionStatus
      ? {
          label: t("labels.models.table.columns.productionStatus"),
          value: t(`labels.model.productionStatus.${model.productionStatus}`),
        }
      : undefined,
  ].filter((stat): stat is HardpointStat => !!stat);
});

const subtitle = computed(() => props.model?.classificationLabel || undefined);

const image = computed(
  () =>
    props.model?.media.storeImage?.smallUrl ??
    props.model?.media.angledView?.smallUrl,
);

const ownRoute = computed(() =>
  props.model?.slug
    ? { name: "ship", params: { slug: props.model.slug } }
    : undefined,
);
</script>

<template>
  <StatsCard
    compact
    :title="model?.name || name || ''"
    variant="slim"
    :subtitle="subtitle"
    :stats="stats"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :loading="loading"
    :unavailable="!loading && !model"
    @navigate="emit('navigate')"
  >
    <img
      v-if="image"
      :src="image"
      :alt="model?.name"
      class="ship-stats-card__image"
      loading="lazy"
    />
  </StatsCard>
</template>

<style lang="scss" scoped>
.ship-stats-card__image {
  display: block;
  width: 100%;
  max-height: 140px;
  object-fit: cover;
  border-radius: var(--radius-control, 8px);
}
</style>
