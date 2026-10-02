<script lang="ts">
export default {
  name: "LocationStarmapFacts",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type Location } from "@/services/fyApi";

type Props = {
  location: Pick<
    Location,
    | "shownOnStarmap"
    | "shownWithParentOnly"
    | "alwaysShown"
    | "quantumTravelDestination"
    | "parent"
    | "mapParent"
  >;
};

const props = defineProps<Props>();

const { t } = useI18n();

// How the in-game map treats the place, which is not always how it nests: the
// map pins Levski at system level under the Nyx star, and Levski sits inside
// Delamar. Said outright rather than smoothed over by our hierarchy.
const visibility = computed(() => {
  const { location } = props;

  if (!location.shownOnStarmap) return t("labels.location.starmapHidden");
  if (location.alwaysShown) return t("labels.location.starmapAlways");
  if (location.shownWithParentOnly && location.parent?.name) {
    return t("labels.location.starmapWithParent", {
      parent: location.parent.name,
    });
  }

  return t("labels.location.starmapShown");
});
</script>

<!-- The rows of a metrics card, which the page draws around them. -->
<template>
  <div class="metrics-card__rows location-starmap">
    <div class="metrics-card__row">
      <span class="metrics-card__row__label">
        {{ t("labels.location.starmapVisibility") }}
      </span>
      <span class="metrics-card__row__value" data-test="starmap-visibility">
        {{ visibility }}
      </span>
    </div>

    <div class="metrics-card__row">
      <span class="metrics-card__row__label">
        {{ t("labels.location.quantumTravel") }}
      </span>
      <span class="metrics-card__row__value">
        {{
          location.quantumTravelDestination
            ? t("labels.location.quantumTravelYes")
            : t("labels.location.quantumTravelNo")
        }}
      </span>
    </div>

    <div
      v-if="location.mapParent"
      class="metrics-card__row metrics-card__row--stack"
    >
      <span class="metrics-card__row__label">
        {{ t("labels.location.mapParent") }}
      </span>
      <span class="metrics-card__row__value" data-test="starmap-map-parent">
        <router-link
          :to="{ name: 'location', params: { slug: location.mapParent.slug } }"
        >
          {{ location.mapParent.name }}
        </router-link>
        <span class="location-starmap__note">
          {{
            t("labels.location.mapParentNote", {
              mapParent: location.mapParent.name,
              parent: location.parent?.name,
            })
          }}
        </span>
      </span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

// The values are sentences rather than figures, so they wrap where a figure
// would be cut short.
.location-starmap .metrics-card__row__value {
  white-space: normal;
}

.location-starmap__note {
  display: block;
  margin-top: 4px;
  font-size: 12px;
  font-weight: 400;
  color: var(--color-text-dim, #959595);
}
</style>
