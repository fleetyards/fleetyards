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

<template>
  <dl class="location-starmap">
    <div class="location-starmap__fact">
      <dt>{{ t("labels.location.starmapVisibility") }}</dt>
      <dd data-test="starmap-visibility">{{ visibility }}</dd>
    </div>

    <div class="location-starmap__fact">
      <dt>{{ t("labels.location.quantumTravel") }}</dt>
      <dd>
        {{
          location.quantumTravelDestination
            ? t("labels.location.quantumTravelYes")
            : t("labels.location.quantumTravelNo")
        }}
      </dd>
    </div>

    <div v-if="location.mapParent" class="location-starmap__fact">
      <dt>{{ t("labels.location.mapParent") }}</dt>
      <dd data-test="starmap-map-parent">
        <router-link
          :to="{ name: 'location', params: { slug: location.mapParent.slug } }"
        >
          {{ location.mapParent.name }}
        </router-link>
        <p class="location-starmap__note">
          {{
            t("labels.location.mapParentNote", {
              mapParent: location.mapParent.name,
              parent: location.parent?.name,
            })
          }}
        </p>
      </dd>
    </div>
  </dl>
</template>

<style lang="scss" scoped>
.location-starmap {
  display: grid;
  gap: 12px;
  margin: 0;

  &__fact {
    display: grid;
    grid-template-columns: minmax(140px, 220px) 1fr;
    gap: 12px;

    @media (max-width: 575px) {
      grid-template-columns: 1fr;
      gap: 2px;
    }
  }

  dt {
    font-size: 13px;
    color: var(--color-text-dim, #959595);
  }

  dd {
    margin: 0;
    font-size: 14px;
    color: var(--color-text, #c8c8c8);
  }

  &__note {
    margin: 4px 0 0;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }
}
</style>
