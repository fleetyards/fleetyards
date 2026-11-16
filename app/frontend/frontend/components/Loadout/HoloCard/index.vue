<script lang="ts">
export default {
  name: "LoadoutHoloCard",
};
</script>

<script lang="ts" setup>
import type {
  HoloCardContent,
  HoloCursor,
} from "@/frontend/composables/useLoadoutHoloCard";

type Props = {
  card: HoloCardContent;
  cursor: HoloCursor;
  testId?: string;
};

withDefaults(defineProps<Props>(), {
  testId: "loadout-holo-card",
});
</script>

<template>
  <div
    class="loadout-holo-card"
    :class="{
      'loadout-holo-card--flip-x': cursor.flipX,
      'loadout-holo-card--flip-y': cursor.flipY,
    }"
    :style="{
      '--card-x': `${cursor.x}px`,
      '--card-y': `${cursor.y}px`,
      '--card-color': card.color,
    }"
    role="tooltip"
    :data-test="testId"
  >
    <span v-if="card.kicker" class="loadout-holo-card__kicker">
      {{ card.kicker }}
    </span>
    <strong class="loadout-holo-card__title">{{ card.title }}</strong>
    <span v-if="card.details.length" class="loadout-holo-card__details">
      {{ card.details.join(" · ") }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
.loadout-holo-card {
  --card-offset: 16px;

  position: absolute;
  top: var(--card-y);
  left: var(--card-x);
  z-index: 3;
  display: flex;
  flex-direction: column;
  gap: 2px;
  max-width: 240px;
  padding: 8px 12px;
  border: 1px solid var(--card-color, var(--color-edge));
  border-radius: 6px;
  background: rgb(10 14 20 / 88%);
  color: var(--color-text);
  font-size: 0.75rem;
  pointer-events: none;
  transform: translate(var(--card-offset), var(--card-offset));

  &--flip-x {
    transform: translate(calc(-100% - var(--card-offset)), var(--card-offset));
  }

  &--flip-y {
    transform: translate(var(--card-offset), calc(-100% - var(--card-offset)));
  }

  &--flip-x#{&}--flip-y {
    transform: translate(
      calc(-100% - var(--card-offset)),
      calc(-100% - var(--card-offset))
    );
  }
}

.loadout-holo-card__kicker {
  color: var(--card-color, var(--color-text-dim));
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 0.625rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.loadout-holo-card__title {
  color: var(--color-lifted);
  font-weight: 600;
}

.loadout-holo-card__details {
  color: var(--color-text-dim);
  font-variant-numeric: tabular-nums;
}
</style>
