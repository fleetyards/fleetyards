<script lang="ts">
export default {
  name: "HardpointHeadline",
};
</script>

<script lang="ts" setup>
type Props = {
  value: string | number;
  unit?: string;
};

defineProps<Props>();
</script>

<template>
  <div class="hardpoint-headline">
    <span class="hardpoint-headline__value">{{ value }}</span>
    <span v-if="unit" class="hardpoint-headline__unit">{{ unit }}</span>
  </div>
</template>

<style lang="scss" scoped>
// The key-metric headline: a right-aligned gold value with a muted unit/label,
// shared by every hardpoint row type so weapons, thrusters, cargo, fuel and
// systems all surface their headline stat the same way.
.hardpoint-headline {
  flex: none;
  margin-left: auto;
  text-align: right;
  line-height: 1.15;
  font-family: "Orbitron", tahoma, sans-serif;
  font-variant-numeric: tabular-nums;
}

.hardpoint-headline__value {
  display: block;
  color: $gold;
  font-weight: 700;
  font-size: 15px;
}

.hardpoint-headline__unit {
  display: block;
  margin-top: 1px;
  color: $gray-light;
  font-size: 10px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}
</style>
