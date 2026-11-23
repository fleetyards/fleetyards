<script lang="ts">
export default {
  name: "StarmapLabel",
};
</script>

<script lang="ts" setup>
type Props = {
  name: string;
  role: string;
  selected?: boolean;
  behind?: boolean;
};

withDefaults(defineProps<Props>(), {
  selected: false,
  behind: false,
});
</script>

<template>
  <span
    :class="[
      'starmap-label',
      `starmap-label--${role}`,
      {
        'starmap-label--selected': selected,
        'starmap-label--behind': behind,
      },
    ]"
  >
    {{ name }}
  </span>
</template>

<style lang="scss" scoped>
// Text on the map rather than in a box: a dark halo keeps it readable over a
// bright surface or nebula without a plate behind every name.
.starmap-label {
  --starmap-label-opacity: 1;

  display: block;
  opacity: var(--starmap-label-opacity);
  animation: starmap-label-in 0.18s ease-out;
  transform: translateY(15px);
  font-size: 0.71875rem;
  line-height: 1.3;
  white-space: nowrap;
  pointer-events: none;
  color: var(--color-text);
  text-shadow:
    0 0 3px rgb(0 0 0 / 95%),
    0 1px 2px rgb(0 0 0 / 95%),
    0 0 8px rgb(0 0 0 / 60%);

  &--planet,
  &--moon {
    font-size: 0.8125rem;
    font-weight: 600;
    color: var(--color-lifted);
  }

  &--moon {
    font-size: 0.75rem;
  }

  &--star,
  &--system {
    transform: translateY(24px);
    font-family: Orbitron, sans-serif;
    font-size: 0.75rem;
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: var(--color-lifted);
  }

  &--selected {
    color: #fff;
  }

  // What it names is on the far side of a body, drawn faintly through it.
  &--behind {
    --starmap-label-opacity: 0.55;

    font-style: italic;
  }

  @media (prefers-reduced-motion: reduce) {
    animation: none;
  }
}

@keyframes starmap-label-in {
  from {
    opacity: 0;
  }

  to {
    opacity: var(--starmap-label-opacity);
  }
}
</style>
