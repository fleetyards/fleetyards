<template>
  <div v-if="station" v-tooltip="tooltip">
    <template v-if="station.classification === 'rest_stop'">
      {{ suffix }}
    </template>
    <template v-else-if="suffix">
      {{ prefix }}
      <router-link
        :to="{
          name: 'celestial-object',
          params: {
            starsystem: location.starsystem?.slug,
            slug: location.slug,
          },
        }"
      >
        {{ location.name }}
      </router-link>
      , {{ suffix }}
    </template>
    <template v-else>
      {{ prefix }}
      <router-link
        :to="{
          name: 'celestial-object',
          params: {
            starsystem: location.starsystem?.slug,
            slug: location.slug,
          },
        }"
      >
        {{ location.name }}
      </router-link>
    </template>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import type { Station } from "@/services/fyApi";
import { StationTypeEnum } from "@/services/fyApi";

type Props = {
  station: Station;
};

const props = defineProps<Props>();

const { t } = useI18n();

const location = computed(() => {
  return props.station.celestialObject;
});

const label = computed(() => {
  if (unref(suffix)) {
    if (unref(location)) {
      return `${unref(prefix)} ${unref(location).name}, ${unref(suffix)}`;
    }

    return unref(suffix);
  }

  return `${unref(prefix)} ${unref(location).name}`;
});

const tooltip = computed(() => {
  if (unref(label)?.length || 0 > 50) {
    return unref(label);
  }

  return null;
});

const prefix = computed(() => {
  switch (props.station.type) {
    case StationTypeEnum.ASTEROID_STATION:
      return t("labels.station.locationPrefix.asteriod");
    case StationTypeEnum.STATION:
      return t("labels.station.locationPrefix.orbit");
    default:
      return t("labels.station.locationPrefix.default");
  }
});

const suffix = computed(() => {
  if (props.station.location) {
    return t("labels.station.locationSuffix", {
      location: props.station.location,
    });
  }

  return null;
});
</script>

<script lang="ts">
export default {
  name: "StationsLocationLabel",
};
</script>
