<script lang="ts">
export default {
  name: "HangarSyncPoints",
};
</script>

<script lang="ts" setup>
type Props = {
  points: { icon: string; text: string }[];
};

defineProps<Props>();
</script>

<template>
  <ul class="sync-points">
    <li v-for="point in points" :key="point.text">
      <i :class="point.icon" aria-hidden="true" />
      {{ point.text }}
    </li>
  </ul>
</template>

<style lang="scss" scoped>
.sync-points {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin: 0;
  padding: 0;
  list-style: none;

  li {
    display: flex;
    align-items: baseline;
    gap: 10px;
    line-height: 1.5;
  }

  i {
    flex-shrink: 0;
    width: 16px;
    color: var(--color-muted, #7a8288);
    text-align: center;
  }
}
</style>
