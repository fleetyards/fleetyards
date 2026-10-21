<script lang="ts">
export default {
  name: "HomeLandingStats",
};
</script>

<script lang="ts" setup>
import NumberFlow from "@number-flow/vue";
import { useStats } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { data: stats } = useStats();

const items = computed(() =>
  stats.value
    ? [
        { key: "ships", value: stats.value.shipsCountTotal },
        { key: "vehicles", value: stats.value.vehiclesCount },
        { key: "fleets", value: stats.value.fleetsCount },
      ]
    : [],
);
</script>

<!-- The live numbers along the foot of the hero: a figure over its label, the
     way a metrics card pairs them. -->
<template>
  <!-- The row's height is held while the numbers load, so nothing below it
       moves when they arrive. -->
  <div class="home-landing-stats-slot">
    <Transition name="fade-quick" appear>
      <dl
        v-if="items.length"
        class="home-landing-stats"
        data-test="home-landing-stats"
      >
        <div
          v-for="item in items"
          :key="item.key"
          class="home-landing-stats__item"
        >
          <dt class="home-landing-stats__label">
            {{ t(`home.landing.stats.${item.key}`) }}
          </dt>
          <dd class="home-landing-stats__value">
            <NumberFlow :value="item.value ?? 0" />
          </dd>
        </div>
      </dl>
    </Transition>
  </div>
</template>

<style lang="scss" scoped>
.home-landing-stats-slot {
  min-height: 46px;
}

.home-landing-stats {
  display: flex;
  justify-content: var(--home-landing-stats-justify, center);
  margin: 0;
}

.home-landing-stats__item {
  display: flex;
  flex-direction: column-reverse;
  align-items: var(--home-landing-stats-align, center);
  gap: 6px;
  padding: 0 40px;

  &:first-child {
    padding-left: var(--home-landing-stats-first-padding, 40px);
  }

  & + & {
    border-left: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  }
}

.home-landing-stats__label {
  color: var(--color-text-dim, #959595);
  font-family: Orbitron, sans-serif;
  font-size: 10px;
  font-weight: 400;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.home-landing-stats__value {
  margin: 0;
  color: var(--color-lifted, #eee);
  font-family: Orbitron, sans-serif;
  font-size: 22px;
}

@media (max-width: 767px) {
  .home-landing-stats {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .home-landing-stats__item,
  .home-landing-stats__item:first-child {
    align-items: center;
    padding: 0 8px;
  }

  .home-landing-stats__label {
    font-size: 9px;
    letter-spacing: 0.12em;
    text-align: center;
  }

  .home-landing-stats__value {
    font-size: 16px;
  }
}
</style>
