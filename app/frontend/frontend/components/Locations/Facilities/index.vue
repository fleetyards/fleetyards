<script lang="ts">
export default {
  name: "LocationFacilities",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import {
  type LocationFacilities,
  LocationFacilitySizeEnum,
} from "@/services/fyApi";

type Props = {
  facilities: LocationFacilities;
};

type Entry = {
  size: LocationFacilitySizeEnum;
  count: number;
};

type Group = {
  key: string;
  label: string;
  note?: string;
  total: number;
  sizes: Entry[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const SIZE_ORDER = Object.values(LocationFacilitySizeEnum);

// One row per size, largest first: a station's hangars come as several
// entries of one size, one per door and pad box.
const bySize = (entries: Entry[]): Entry[] => {
  const counts = new Map<LocationFacilitySizeEnum, number>();

  entries.forEach((entry) => {
    counts.set(entry.size, (counts.get(entry.size) ?? 0) + entry.count);
  });

  return [...counts.entries()]
    .map(([size, count]) => ({ size, count }))
    .sort((a, b) => SIZE_ORDER.indexOf(b.size) - SIZE_ORDER.indexOf(a.size));
};

const group = (
  key: string,
  label: string,
  entries: Entry[],
  note?: string,
): Group[] => {
  const sizes = bySize(entries);
  if (!sizes.length) return [];

  return [
    {
      key,
      label,
      note,
      total: sizes.reduce((sum, entry) => sum + entry.count, 0),
      sizes,
    },
  ];
};

// A free pad is one a pilot lands on without ATC handing it out.
const groups = computed((): Group[] => {
  const { hangars, landingPads, vehiclePads } = props.facilities;

  return [
    ...group(
      "hangars",
      t("labels.location.hangars"),
      hangars,
      t("labels.location.hangarsNote"),
    ),
    ...group(
      "free-landing-pads",
      t("labels.location.freeLandingPads"),
      landingPads.filter((pad) => !pad.atcAssigned),
      t("labels.location.freeLandingPadsNote"),
    ),
    ...group(
      "landing-pads",
      t("labels.location.landingPads"),
      landingPads.filter((pad) => pad.atcAssigned),
    ),
    ...group("vehicle-pads", t("labels.location.vehiclePads"), vehiclePads),
  ];
});
</script>

<template>
  <section class="location-facilities">
    <div
      v-for="entry in groups"
      :key="entry.key"
      class="location-facilities__group"
      :data-test="`facilities-${entry.key}`"
    >
      <div class="location-facilities__heading">
        <span class="location-facilities__kind">{{ entry.label }}</span>
        <span class="location-facilities__total">{{ entry.total }}</span>
      </div>

      <dl class="metrics-card__rows">
        <div
          v-for="size in entry.sizes"
          :key="size.size"
          class="metrics-card__row"
        >
          <dt class="metrics-card__row__label">
            {{ t(`labels.shipSizes.${size.size}`) }}
          </dt>
          <dd class="metrics-card__row__value">{{ size.count }}</dd>
        </div>
      </dl>

      <p v-if="entry.note" class="location-facilities__note">
        {{ entry.note }}
      </p>
    </div>

    <div
      v-if="facilities.dockingTubes"
      class="location-facilities__heading"
      data-test="facilities-docking-tubes"
    >
      <span class="location-facilities__kind">
        {{ t("labels.location.dockingTubes") }}
      </span>
      <span class="location-facilities__total">
        {{ facilities.dockingTubes }}
      </span>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

// Inside a metrics card, which draws the frame and the title.
.location-facilities {
  display: flex;
  flex-direction: column;
  gap: 14px;

  &__group {
    display: flex;
    flex-direction: column;
  }

  &__heading {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 12px;
  }

  &__kind {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 11px;
    font-weight: 600;
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }

  &__total {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 14px;
    font-weight: 600;
    font-variant-numeric: tabular-nums;
  }

  &__note {
    margin: 4px 0 0;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }

  .metrics-card__row {
    padding: 5px 0;
  }
}
</style>
