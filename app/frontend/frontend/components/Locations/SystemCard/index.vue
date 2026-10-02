<script lang="ts">
export default {
  name: "LocationSystemCard",
};
</script>

<script lang="ts" setup>
import SystemStrip from "@/frontend/components/Locations/SystemStrip/index.vue";
import SystemCardSkeleton from "@/frontend/components/Locations/SystemCard/Skeleton.vue";
import { type Location, useLocationTree } from "@/services/fyApi";

type Props = {
  system: Location;
};

const props = defineProps<Props>();

const { data: tree } = useLocationTree(computed(() => props.system.slug));
</script>

<template>
  <div class="location-system-card">
    <router-link
      :to="{ name: 'location', params: { slug: system.slug } }"
      class="location-system-card__title"
    >
      {{ system.name }}
    </router-link>
    <SystemStrip v-if="tree" :tree="tree" compact />
    <SystemCardSkeleton v-else :with-title="false" />
  </div>
</template>

<style lang="scss" scoped>
.location-system-card {
  display: flex;
  flex-direction: column;
  gap: 8px;

  &__title {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 16px;
    color: var(--color-text, #c8c8c8);
  }
}
</style>
