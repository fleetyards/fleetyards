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
};

withDefaults(defineProps<Props>(), {
  selected: false,
});
</script>

<template>
  <span
    :class="[
      'starmap-label',
      `starmap-label--${role}`,
      { 'starmap-label--selected': selected },
    ]"
  >
    {{ name }}
  </span>
</template>

<style lang="scss" scoped>
.starmap-label {
  display: block;
  transform: translateY(14px);
  // A faint backing, so a name still reads over a body's bright ice or cloud.
  padding: 0 4px;
  border-radius: 3px;
  background: rgb(5 10 18 / 45%);
  font-size: 0.6875rem;
  font-weight: 500;
  white-space: nowrap;
  pointer-events: none;
  color: rgb(255 255 255 / 60%);
  text-shadow: 0 0 4px rgb(0 0 0 / 90%);

  &--system,
  &--star,
  &--planet {
    font-size: 0.75rem;
    font-weight: 700;
    color: rgb(255 255 255 / 85%);
  }

  &--selected {
    color: var(--color-primary);
  }
}
</style>
