<script lang="ts">
export default {
  name: "LocationStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import LocationGlobe from "@/frontend/components/Locations/Globe/index.vue";
import LocationKindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import { isGlobeKind, sunStyle } from "@/shared/utils/LocationGlobe";
import {
  type StatsCardBadge,
  type StatsCardStatus,
} from "@/frontend/components/StatsCard/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Location,
  LocationKindEnum,
  NullableLocationArmisticeEnum,
} from "@/services/fyApi";

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

// Retired outranks unstable: a star the build dropped is not flaring.
const status = computed<StatsCardStatus | undefined>(() => {
  if (props.location?.retired) {
    return { label: t("labels.location.retired"), tone: "neutral" };
  }

  if (props.location?.unstable) {
    return { label: t("labels.location.unstable"), tone: "warning" };
  }

  // Then whether the place keeps any law, which a pilot needs to know before
  // going there.
  if (props.location?.lawful === false) {
    return { label: t("labels.location.unlawful"), tone: "warning" };
  }

  if (props.location?.lawful) {
    return { label: t("labels.location.lawful"), tone: "success" };
  }

  return undefined;
});

const sum = (entries?: { count: number }[]) =>
  (entries ?? []).reduce((total, entry) => total + entry.count, 0);

const badges = computed<StatsCardBadge[]>(() => {
  const location = props.location;
  if (!location) return [];

  const yesNo = (value: boolean) =>
    value
      ? t("labels.location.quantumTravelYes")
      : t("labels.location.quantumTravelNo");

  const list: StatsCardBadge[] = [];

  // Where a ship can set down, as the location page counts it.
  const facilities = location.facilities;
  const hangars = sum(facilities?.hangars);
  const pads = sum(facilities?.landingPads);

  if (hangars) {
    list.push({
      key: "hangars",
      label: t("labels.location.hangars"),
      value: String(hangars),
    });
  }

  if (pads) {
    list.push({
      key: "pads",
      label: t("labels.location.landingPads"),
      value: String(pads),
    });
  }

  if (facilities?.dockingTubes) {
    list.push({
      key: "docking",
      label: t("labels.location.dockingTubes"),
      value: String(facilities.dockingTubes),
    });
  }

  // What a hauler can do there: its terminals, whether one has a freight
  // elevator, and the largest container any of them takes.
  const terminals = location.terminals ?? [];

  if (terminals.length) {
    list.push({
      key: "terminals",
      label: t("labels.location.terminals"),
      value: String(terminals.length),
    });
    list.push({
      key: "freight",
      label: t("labels.location.freightElevator"),
      value: yesNo(terminals.some((terminal) => terminal.hasFreightElevator)),
    });

    const largest = Math.max(
      0,
      ...terminals.map((terminal) => terminal.maxContainerSize ?? 0),
    );

    if (largest) {
      list.push({
        key: "container",
        label: t("labels.location.maxContainer"),
        value: String(largest),
        unit: "SCU",
      });
    }
  }

  if (location.shopsCount) {
    list.push({
      key: "shops",
      label: t("labels.location.shops"),
      value: String(location.shopsCount),
    });
  }

  list.push({
    key: "quantum",
    label: t("labels.location.quantumTravel"),
    value: yesNo(location.quantumTravelDestination),
  });

  if (location.childrenCount) {
    list.push({
      key: "places",
      label: t("labels.location.places"),
      value: String(location.childrenCount),
    });
  }

  // Whether weapons are off there, and whether parts of it are trespassing.
  if (location.armistice) {
    list.push({
      key: "armistice",
      label: t("labels.location.armistice"),
      value:
        location.armistice === NullableLocationArmisticeEnum.WHOLE
          ? yesNo(true)
          : t("labels.location.armisticePartial"),
    });
  }

  if (location.trespassAreas) {
    list.push({
      key: "trespass",
      label: t("labels.location.trespassAreas"),
      value: yesNo(true),
    });
  }

  // Last, on a row of its own: its name is longer than a third of the card.
  if (location.jurisdiction) {
    list.push({
      key: "jurisdiction",
      label: t("labels.location.jurisdiction"),
      value: location.jurisdiction,
      wide: true,
    });
  }

  return list;
});

const image = computed(() => {
  const picture = props.location?.image;

  return picture ? (picture.mediumUrl ?? picture.url) : undefined;
});

// A planet or a moon turns as its globe, a star glows as its sun; anything
// else shows its kind's glyph in the card's own icon box.
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
    <template v-else-if="location" #glyph>
      <LocationKindIcon :kind="location.kind" />
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
