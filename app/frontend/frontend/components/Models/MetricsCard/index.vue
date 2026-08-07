<script lang="ts">
export default {
  name: "MetricsCard",
};
</script>

<script lang="ts" setup>
type Props = {
  title: string;
  variant?: "default" | "slim";
};

withDefaults(defineProps<Props>(), {
  variant: "default",
});
</script>

<template>
  <div class="metrics-card" :class="`metrics-card--${variant}`">
    <div class="metrics-card__head">
      <span class="metrics-card__title">
        <span class="metrics-card__dot" />
        {{ title }}
      </span>
      <slot name="head" />
    </div>
    <div class="metrics-card__body">
      <slot />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.metrics-card {
  position: relative;
  margin: 15px 0 40px;
  background: $panel-bg;
  border: 2px solid rgba($gray-light, 0.5);
  border-radius: 16px;
  box-shadow: 0 6px 18px -12px rgba(#000, 0.8);
}

.metrics-card::before,
.metrics-card::after {
  content: "";
  position: absolute;
  left: 34px;
  right: 34px;
  height: 3px;
  background: #4a4f54;
  border-radius: 1px;
}

.metrics-card::before {
  top: -2px;
}

.metrics-card::after {
  bottom: -2px;
}

.metrics-card__head {
  padding: 16px 18px 12px;
}

.metrics-card__title {
  display: flex;
  align-items: center;
  gap: 11px;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 15px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: lighten($text-color, 15%);
}

.metrics-card__dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: $gold;
  box-shadow: 0 0 10px 1px rgba($gold, 0.55);
}

.metrics-card__body {
  padding: 4px 18px 18px;
}

// Lightweight variant for repeated cards (e.g. hardpoint groups) that would be
// too heavy at full strength: no end-caps, single border, quieter shadow, and a
// header divider so groups still read as part of the metrics-card family.
.metrics-card--slim {
  margin: 0 0 22px;
  border-width: 1px;
  border-radius: 12px;
  box-shadow: 0 6px 20px -14px rgba(#000, 0.9);
}

.metrics-card--slim::before,
.metrics-card--slim::after {
  display: none;
}

.metrics-card--slim .metrics-card__head {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  border-bottom: 1px solid rgba($gray-light, 0.28);
  background: rgba(#000, 0.12);
}

.metrics-card--slim .metrics-card__title {
  font-size: 13px;
}

.metrics-card--slim .metrics-card__body {
  padding: 6px 14px 14px;
}
</style>
