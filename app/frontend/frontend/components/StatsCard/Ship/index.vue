<script lang="ts">
export default {
  name: "ShipStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import {
  type StatsCardBadge,
  type StatsCardStatus,
  type StatsCardStatusTone,
} from "@/frontend/components/StatsCard/types";
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

// Flyable is the state worth calling out. Hangar ready is not flyable, so it
// stays neutral with the other steps on the way.
const STATUS_TONES: Record<string, StatsCardStatusTone> = {
  "flight-ready": "success",
  "in-production": "warning",
};

const status = computed<StatsCardStatus | undefined>(() => {
  const productionStatus = props.model?.productionStatus;
  if (!productionStatus) return undefined;

  return {
    label: t(`labels.model.productionStatus.${productionStatus}`),
    tone: STATUS_TONES[productionStatus] ?? "neutral",
  };
});

const badges = computed<StatsCardBadge[]>(() => {
  const model = props.model;
  if (!model) return [];

  return [
    model.crew.label
      ? {
          key: "crew",
          label: t("labels.model.crew"),
          value: model.crew.label,
        }
      : undefined,
    model.pledgePriceLabel
      ? {
          key: "pledge",
          label: t("labels.model.pledgePrice"),
          value: model.pledgePriceLabel,
        }
      : undefined,
  ].filter((badge): badge is StatsCardBadge => !!badge);
});

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
    kind="Model"
    :category="model?.classificationLabel || undefined"
    :subtitle="model?.manufacturer.name"
    :status="status"
    :image="image"
    :badges="badges"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :loading="loading"
    :unavailable="!loading && !model"
    @navigate="emit('navigate')"
  />
</template>
