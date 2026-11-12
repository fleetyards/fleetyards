<script lang="ts">
export default {
  name: "LandingServiceIcons",
};
</script>

<script lang="ts" setup>
import type { LandingServiceIcon } from "@/shared/utils/LandingServices";

type Props = {
  services: LandingServiceIcon[];
  // Each icon with its name beside it, rather than the name as its tooltip.
  withLabels?: boolean;
};

withDefaults(defineProps<Props>(), {
  withLabels: false,
});
</script>

<template>
  <span
    class="landing-service-icons"
    :class="{ 'landing-service-icons--labelled': withLabels }"
  >
    <span
      v-for="service in services"
      :key="service.key"
      v-tooltip="withLabels || !service.url ? undefined : service.label"
      class="landing-service-icons__service"
      :data-test="`landing-service-${service.key}`"
    >
      <img
        v-if="service.url"
        :src="service.url"
        :alt="service.label"
        class="landing-service-icons__icon"
      />
      <span v-if="withLabels || !service.url">{{ service.label }}</span>
    </span>
  </span>
</template>

<style lang="scss" scoped>
.landing-service-icons {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;

  &--labelled {
    gap: 6px 16px;
  }

  &__service {
    display: inline-flex;
    align-items: center;
    gap: 6px;
  }

  &__icon {
    width: var(--landing-service-icon-size, 20px);
    height: var(--landing-service-icon-size, 20px);
    flex: none;
  }
}
</style>
