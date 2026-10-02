<script lang="ts">
export default {
  name: "LocationStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import LocationGlobe from "@/frontend/components/Locations/Globe/index.vue";
import { isGlobeKind, sunStyle } from "@/shared/utils/LocationGlobe";
import {
  type StatsCardBadge,
  type StatsCardStatus,
} from "@/frontend/components/StatsCard/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Location, LocationKindEnum } from "@/services/fyApi";

type Props = {
  location?: Location;
  name?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  location: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();

const category = computed(() =>
  props.location?.kind
    ? t(`labels.location.kinds.${props.location.kind}`)
    : undefined,
);

// Where it is, outermost first, as the breadcrumbs say it -- without the star,
// which every place in a system sits under.
const subtitle = computed(() => {
  const names = (props.location?.ancestors ?? [])
    .filter((ancestor) => ancestor.kind !== LocationKindEnum.STAR)
    .map((ancestor) => ancestor.name)
    .filter(Boolean);

  return names.length ? names.join(" · ") : undefined;
});

const status = computed<StatsCardStatus | undefined>(() =>
  props.location?.retired
    ? { label: t("labels.location.retired"), tone: "neutral" }
    : undefined,
);

const badges = computed<StatsCardBadge[]>(() => {
  const location = props.location;
  if (!location) return [];

  const list: StatsCardBadge[] = [
    {
      key: "quantum",
      label: t("labels.location.quantumTravel"),
      value: location.quantumTravelDestination
        ? t("labels.location.quantumTravelYes")
        : t("labels.location.quantumTravelNo"),
    },
  ];

  if (location.childrenCount) {
    list.push({
      key: "places",
      label: t("labels.location.places"),
      value: String(location.childrenCount),
    });
  }

  return list;
});

const image = computed(() => {
  const picture = props.location?.image;

  return picture ? (picture.mediumUrl ?? picture.url) : undefined;
});

// A planet or a moon turns as its globe, a star glows as its sun; anything
// else keeps the card's own icon.
const drawn = computed(() => {
  const kind = props.location?.kind;

  if (isGlobeKind(kind)) return "globe";
  if (kind === LocationKindEnum.STAR) return "sun";

  return undefined;
});

const ownRoute = computed(() =>
  props.location?.slug
    ? { name: "location", params: { slug: props.location.slug } }
    : undefined,
);
</script>

<template>
  <StatsCard
    compact
    :title="location?.name || name || ''"
    kind="Location"
    :category="category"
    :subtitle="subtitle"
    :status="status"
    :image="image"
    :description="location?.description ?? undefined"
    :badges="badges"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :loading="loading"
    :unavailable="!loading && !location"
    @navigate="emit('navigate')"
  >
    <template v-if="drawn && location" #icon>
      <LocationGlobe
        v-if="drawn === 'globe'"
        class="location-stats-card__globe"
        :location="location"
      />
      <span
        v-else
        class="location-stats-card__sun"
        :class="{ 'location-stats-card__sun--unstable': location.unstable }"
        :style="sunStyle(location)"
        aria-hidden="true"
      />
    </template>
  </StatsCard>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Locations/sun";

.location-stats-card__globe,
.location-stats-card__sun {
  display: block;
  width: 30px;
  height: 30px;
  border-radius: 50%;
}

.location-stats-card__sun {
  @include location-sun;

  &--unstable {
    @include location-sun-unstable;
  }
}
</style>
