<script lang="ts">
export default {
  name: "LocationSystemStrip",
};
</script>

<script lang="ts" setup>
import LocationKindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import { globeStyle, sunStyle } from "@/shared/utils/LocationGlobe";
import { useI18n } from "@/shared/composables/useI18n";
import { LocationKindEnum, type LocationTreeNode } from "@/services/fyApi";

type Props = {
  tree: LocationTreeNode;
  // The place being read and the places it sits in, which the strip lights.
  path?: string[];
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  path: () => [],
  compact: false,
});

const { t } = useI18n();

const star = computed(() =>
  props.tree.children.find((node) => node.location.kind === "star"),
);

// The bodies in orbit order. A system without a star record -- Ellis, built
// from its translation -- holds its planets itself.
const bodies = computed(() => star.value?.children ?? props.tree.children);

const gateways = computed(() => star.value?.gateways ?? []);

const isLit = (id: string) => props.path.includes(id);

// The lit body's moons and cities, shown under it in the compact strip so a
// moon page says which planet it orbits and which of its siblings it is.
const litBody = computed(() =>
  bodies.value.find((node) => isLit(node.location.id)),
);
</script>

<template>
  <section
    class="location-strip"
    :class="{ 'location-strip--compact': compact }"
    :aria-label="
      t('labels.location.systemStrip', { system: tree.location.name })
    "
  >
    <router-link
      v-if="star"
      :to="{ name: 'location', params: { slug: tree.location.slug } }"
      class="location-strip__star"
    >
      <span
        class="location-strip__sun"
        :style="sunStyle(star.location)"
        aria-hidden="true"
      />
      <span class="location-strip__name">{{ star.location.name }}</span>
    </router-link>

    <ol class="location-strip__orbit">
      <li
        v-for="body in bodies"
        :key="body.location.id"
        class="location-strip__body"
        :class="{ 'location-strip__body--lit': isLit(body.location.id) }"
      >
        <router-link
          :to="{ name: 'location', params: { slug: body.location.slug } }"
          class="location-strip__body-link"
          :aria-current="path.at(-1) === body.location.id ? 'page' : undefined"
        >
          <span
            class="location-strip__planet"
            :style="globeStyle(body.location)"
            aria-hidden="true"
          />
          <span class="location-strip__name">{{ body.location.name }}</span>
        </router-link>

        <ul
          v-if="compact && litBody?.location.id === body.location.id"
          class="location-strip__moons"
        >
          <li v-for="moon in body.children" :key="moon.location.id">
            <router-link
              :to="{ name: 'location', params: { slug: moon.location.slug } }"
              class="location-strip__moon"
              :class="{ 'location-strip__moon--lit': isLit(moon.location.id) }"
            >
              <span
                v-if="globeStyle(moon.location)"
                class="location-strip__moon-globe"
                :style="globeStyle(moon.location)"
                aria-hidden="true"
              />
              <LocationKindIcon v-else :kind="moon.location.kind" />
              {{ moon.location.name }}
            </router-link>
          </li>
        </ul>
      </li>
    </ol>

    <div v-if="!compact && gateways.length" class="location-strip__gateways">
      <span class="location-strip__caption">
        {{ t("labels.location.gateways") }}
      </span>
      <router-link
        v-for="gateway in gateways"
        :key="gateway.id"
        :to="{ name: 'location', params: { slug: gateway.slug } }"
        class="location-strip__gateway"
      >
        <LocationKindIcon :kind="LocationKindEnum.JUMP_POINT" />
        {{ gateway.name }}
      </router-link>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
