<script lang="ts">
export default {
  name: "LocationPlaceholderSystemCard",
};
</script>

<script lang="ts" setup>
import LocationGlobe from "@/frontend/components/Locations/Globe/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { sunStyle } from "@/shared/utils/LocationGlobe";
import type { PlaceholderSystem } from "./placeholders";

type Props = {
  system: PlaceholderSystem;
};

defineProps<Props>();

const { t } = useI18n();

const body = ref<HTMLElement | null>(null);

defineExpose({ body });
</script>

<!-- A system card's shape with nothing to link to: no page exists yet for the
     system or anything in it. -->
<template>
  <div class="location-placeholder-card" data-test="placeholder-system">
    <div class="location-placeholder-card__head">
      <span class="location-placeholder-card__title">{{ system.name }}</span>
      <span class="location-placeholder-card__note">
        {{ t("labels.location.notInGameYet") }}
      </span>
    </div>
    <div ref="body" class="location-placeholder-card__strip">
      <div class="location-placeholder-card__body">
        <span
          class="location-placeholder-card__sun"
          :style="sunStyle({ kind: 'star', color: system.star.color })"
          aria-hidden="true"
        />
        <span class="location-placeholder-card__name">
          {{ system.star.name }}
        </span>
      </div>
      <ol class="location-placeholder-card__orbit">
        <li
          v-for="planet in system.planets"
          :key="planet.name"
          class="location-placeholder-card__body"
        >
          <LocationGlobe
            class="location-placeholder-card__planet"
            :location="{ kind: 'planet', ...planet }"
          />
          <span class="location-placeholder-card__name">{{ planet.name }}</span>
        </li>
      </ol>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Locations/sun";

// At the compact strip's sizes and drawn the same way, so a placeholder lines
// up with the cards around it; the dashed panel and the dimmed names keep it
// from passing for one.
.location-placeholder-card {
  display: flex;
  flex-direction: column;
  gap: 8px;

  &__head {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 8px 16px;
  }

  &__title {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 16px;
    color: var(--color-text-dim, #959595);
  }

  &__note {
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }

  &__strip {
    display: flex;
    align-items: flex-start;
    gap: 28px;
    min-height: 122px;
    padding: 14px 20px;
    box-sizing: border-box;
    background-color: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px dashed var(--color-edge-soft, rgb(122 130 136 / 0.45));
    border-radius: var(--radius-surface-slim, 12px);
    overflow-x: auto;
  }

  &__orbit {
    position: relative;
    display: flex;
    flex-grow: 1;
    justify-content: space-around;
    gap: 24px;
    margin: 0;
    padding: 0;
    list-style: none;

    &::before {
      content: "";
      position: absolute;
      left: 0;
      right: 0;
      top: 22px;
      border-top: 1px dashed var(--color-edge-soft, rgb(122 130 136 / 0.45));
    }
  }

  &__body {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
    flex-shrink: 0;
  }

  &__sun,
  &__planet {
    display: block;
    flex-shrink: 0;
    aspect-ratio: 1;
    border-radius: 50%;
    background-color: #1d2329;
    border: 1px solid
      var(--globe-border, var(--color-edge-soft, rgb(122 130 136 / 0.55)));
  }

  &__sun {
    @include location-sun;

    width: 64px;
    height: 64px;
  }

  &__planet {
    width: 44px;
    height: 44px;
  }

  &__name {
    font-size: 13px;
    font-weight: 600;
    white-space: nowrap;
    color: var(--color-text-dim, #959595);
  }
}
</style>
