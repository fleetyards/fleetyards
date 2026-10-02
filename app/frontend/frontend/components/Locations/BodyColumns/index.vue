<script lang="ts">
export default {
  name: "LocationBodyColumns",
};
</script>

<script lang="ts" setup>
import LocationKindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import KindCounts from "@/frontend/components/Locations/KindCounts/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { LocationKindEnum, type LocationTreeNode } from "@/services/fyApi";
import { globeStyle } from "@/shared/utils/LocationGlobe";

type Props = {
  bodies: LocationTreeNode[];
  // What the counts under a body are: around a planet, "in orbit"; on a moon
  // they are the places on it.
  countsLabel?: string;
};

withDefaults(defineProps<Props>(), {
  countsLabel: undefined,
});

const { t } = useI18n();

const moons = (body: LocationTreeNode) =>
  body.children.filter((child) => child.location.kind !== "city");

const cities = (body: LocationTreeNode) =>
  body.children.filter((child) => child.location.kind === "city");
</script>

<template>
  <div class="location-columns">
    <section
      v-for="body in bodies"
      :key="body.location.id"
      class="location-columns__body"
    >
      <router-link
        :to="{ name: 'location', params: { slug: body.location.slug } }"
        class="location-columns__head"
      >
        <span
          class="location-columns__planet"
          :style="globeStyle(body.location)"
          aria-hidden="true"
        />
        <span class="location-columns__title">{{ body.location.name }}</span>
      </router-link>

      <router-link
        v-for="city in cities(body)"
        :key="city.location.id"
        :to="{ name: 'location', params: { slug: city.location.slug } }"
        class="location-columns__city"
      >
        <LocationKindIcon :kind="LocationKindEnum.CITY" />
        {{ city.location.name }}
      </router-link>

      <div v-if="moons(body).length" class="location-columns__group">
        <span class="location-columns__caption">
          {{ t("labels.location.moons", { count: moons(body).length }) }}
        </span>
        <router-link
          v-for="moon in moons(body)"
          :key="moon.location.id"
          :to="{ name: 'location', params: { slug: moon.location.slug } }"
          class="location-columns__moon"
        >
          <span
            v-if="globeStyle(moon.location)"
            class="location-columns__moon-dot"
            :style="globeStyle(moon.location)"
            aria-hidden="true"
          />
          <span
            v-else
            class="location-columns__moon-dot location-columns__moon-dot--icon"
            aria-hidden="true"
          >
            <LocationKindIcon :kind="moon.location.kind" />
          </span>
          <span class="location-columns__moon-body">
            <span class="location-columns__moon-name">
              {{ moon.location.name }}
            </span>
            <KindCounts :counts="moon.counts" />
            <span
              v-for="city in cities(moon)"
              :key="city.location.id"
              class="location-columns__moon-city"
            >
              <LocationKindIcon :kind="LocationKindEnum.CITY" />
              {{ city.location.name }}
            </span>
          </span>
        </router-link>
      </div>

      <div v-if="body.counts.length" class="location-columns__group">
        <span class="location-columns__caption">
          {{ countsLabel ?? t("labels.location.inOrbit") }}
        </span>
        <KindCounts :counts="body.counts" />
      </div>

      <div v-if="body.lagrangePoints.length" class="location-columns__group">
        <span class="location-columns__caption">
          {{ t("labels.location.lagrangePoints") }}
        </span>
        <div class="location-columns__chips">
          <router-link
            v-for="point in body.lagrangePoints"
            :key="point.id"
            :to="{ name: 'location', params: { slug: point.slug } }"
            class="location-columns__chip"
          >
            {{ point.name }}
          </router-link>
        </div>
      </div>
    </section>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
