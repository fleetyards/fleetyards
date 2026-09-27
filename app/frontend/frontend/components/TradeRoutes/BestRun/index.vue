<script lang="ts">
export default {
  name: "TradeRoutesBestRun",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useTradeRouteFormat } from "@/frontend/composables/useTradeRouteFormat";
import { type TradeRoute } from "@/services/fyApi";

type Props = {
  route: TradeRoute;
  shipCargo?: number;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { figure, location, pricesAge, limitLabel } = useTradeRouteFormat();

const hasShip = computed(() => props.route.loadableScu != null);

const loadShare = computed(() => {
  if (!props.shipCargo || props.route.loadableScu == null) return 0;

  return Math.min(
    100,
    Math.round((props.route.loadableScu / props.shipCargo) * 100),
  );
});

const crossesSystems = computed(
  () =>
    props.route.originTerminal.starSystem !==
    props.route.destinationTerminal.starSystem,
);
</script>

<template>
  <section class="best-run" aria-labelledby="best-run-heading">
    <div class="best-run__trip">
      <span id="best-run-heading" class="best-run__kicker">
        {{ t("labels.tradeRoutes.bestRun") }}
      </span>
      <router-link
        class="best-run__commodity"
        :to="{ name: 'commodity', params: { slug: route.commodity.slug } }"
      >
        {{ route.commodity.name }}
      </router-link>

      <div class="best-run__legs">
        <div class="best-run__leg">
          <span class="best-run__label">{{
            t("labels.tradeRoutes.buyAt")
          }}</span>
          <span class="best-run__terminal">{{
            route.originTerminal.name
          }}</span>
          <span class="best-run__where">{{
            location(route.originTerminal)
          }}</span>
          <span class="best-run__price">
            {{
              t("labels.tradeRoutes.pricePerScu", {
                price: figure(route.priceOrigin),
              })
            }}
          </span>
        </div>

        <div class="best-run__hop" aria-hidden="true">
          <span v-if="route.distance != null">
            {{
              t("labels.tradeRoutes.distanceValue", { count: route.distance })
            }}
          </span>
          <svg width="120" height="14" viewBox="0 0 120 14" fill="none">
            <circle
              cx="6"
              cy="7"
              r="5"
              stroke="currentColor"
              stroke-width="2"
            />
            <path
              d="M13 7h92"
              stroke="currentColor"
              stroke-width="2"
              stroke-dasharray="4 4"
            />
            <path
              d="m104 2 8 5-8 5"
              stroke="currentColor"
              stroke-width="2"
              stroke-linejoin="round"
            />
          </svg>
          <span v-if="crossesSystems" class="best-run__jump">
            {{
              t("labels.tradeRoutes.jumpTo", {
                system: route.destinationTerminal.starSystem,
              })
            }}
          </span>
        </div>

        <div class="best-run__leg">
          <span class="best-run__label">{{
            t("labels.tradeRoutes.sellAt")
          }}</span>
          <span class="best-run__terminal">{{
            route.destinationTerminal.name
          }}</span>
          <span class="best-run__where">{{
            location(route.destinationTerminal)
          }}</span>
          <span class="best-run__price">
            {{
              t("labels.tradeRoutes.pricePerScu", {
                price: figure(route.priceDestination),
              })
            }}
          </span>
        </div>
      </div>

      <div class="best-run__meta">
        <span v-if="pricesAge(route)" class="best-run__age">
          <i class="fa-light fa-clock" aria-hidden="true" />
          {{ t("labels.tradeRoutes.pricesFrom", { time: pricesAge(route) }) }}
        </span>
        <slot name="others" />
      </div>
    </div>

    <div class="best-run__numbers">
      <div class="best-run__profit">
        <span class="best-run__label">
          {{
            hasShip
              ? t("labels.tradeRoutes.profitThisRun")
              : t("labels.tradeRoutes.profitPerScu")
          }}
        </span>
        <span class="best-run__profit-value">
          +{{ figure(hasShip ? route.profitPerRun : route.profitPerScu) }}
        </span>
        <span class="best-run__hint">
          <template v-if="hasShip">
            {{
              t("labels.tradeRoutes.aUecPerScu", {
                value: figure(route.profitPerScu),
              })
            }}
          </template>
          <template v-else>aUEC</template>
        </span>
      </div>

      <template v-if="hasShip">
        <div class="best-run__load">
          <div class="best-run__line">
            <span>{{ t("labels.tradeRoutes.load") }}</span>
            <strong>
              {{
                shipCargo
                  ? t("labels.tradeRoutes.loadOf", {
                      load: route.loadableScu,
                      cargo: shipCargo,
                    })
                  : t("labels.tradeRoutes.scu", {
                      count: route.loadableScu ?? 0,
                    })
              }}
            </strong>
          </div>
          <div class="best-run__bar">
            <span :style="{ width: `${loadShare}%` }" />
          </div>
          <span :class="`best-run__limit best-run__limit--${route.loadLimit}`">
            {{ limitLabel(route) }}
          </span>
        </div>
        <div class="best-run__line">
          <span>{{ t("labels.tradeRoutes.youSpend") }}</span>
          <strong>{{ figure(route.investment) }} aUEC</strong>
        </div>
      </template>
      <p v-else class="best-run__hint">
        {{ t("labels.tradeRoutes.pickShipForRun") }}
      </p>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.best-run {
  display: grid;
  grid-template-columns: minmax(0, 1.6fr) minmax(0, 1fr);
  overflow: hidden;
  border: 1px solid var(--color-primary, #428bca);
  border-radius: 10px;
  background: $panel-bg;
}

.best-run__trip {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 28px 32px;
}

.best-run__kicker {
  color: var(--color-primary-tint, #92bce0);
  font-family: Orbitron, sans-serif;
  font-size: 0.8rem;
  font-weight: 700;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

.best-run__commodity {
  color: #fff;
  font-size: 1.9rem;
  font-weight: 700;
  line-height: 1.2;
}

.best-run__legs {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 130px minmax(0, 1fr);
  align-items: center;
  gap: 16px;
}

.best-run__leg {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.best-run__label {
  color: var(--color-text-dim, #959595);
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.best-run__terminal {
  color: #fff;
  font-size: 1.15rem;
  font-weight: 700;
}

.best-run__where,
.best-run__jump,
.best-run__hint {
  color: var(--color-text-dim, #959595);
  font-size: 0.85rem;
}

.best-run__price {
  margin-top: 4px;
}

.best-run__hop {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  color: var(--color-primary, #428bca);
  font-size: 0.85rem;

  span:first-child {
    color: var(--color-text, #c8c8c8);
  }
}

.best-run__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
}

.best-run__age {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 999px;
  background: $gray-darker;
  font-size: 0.85rem;
}

.best-run__numbers {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 20px;
  padding: 28px 32px;
  border-left: 1px solid $gray-dark;
  background: $gray-black;
}

.best-run__profit {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.best-run__profit-value {
  color: var(--color-success-tint, #6fcf6f);
  font-family: Orbitron, sans-serif;
  font-size: 2.5rem;
  font-weight: 700;
  line-height: 1.1;
}

.best-run__load {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.best-run__line {
  display: flex;
  justify-content: space-between;
  gap: 12px;

  span {
    color: var(--color-text-dim, #959595);
  }

  strong {
    color: #fff;
  }
}

.best-run__bar {
  height: 8px;
  overflow: hidden;
  border-radius: 4px;
  background: $gray-darker;

  span {
    display: block;
    height: 100%;
    background: var(--color-primary, #428bca);
  }
}

.best-run__limit {
  font-size: 0.85rem;
}

.best-run__limit--hold {
  color: var(--color-text-dim, #959595);
}

.best-run__limit--stock,
.best-run__limit--demand {
  color: #e0a15c;
}

.best-run__limit--budget {
  color: #b9a3e3;
}

@media (max-width: $desktop-breakpoint) {
  .best-run {
    grid-template-columns: minmax(0, 1fr);
  }

  .best-run__trip,
  .best-run__numbers {
    padding: 16px;
  }

  .best-run__numbers {
    border-top: 1px solid $gray-dark;
    border-left: 0;
  }

  .best-run__commodity {
    font-size: 1.4rem;
  }

  .best-run__legs {
    grid-template-columns: minmax(0, 1fr);
    gap: 10px;
  }

  .best-run__hop {
    flex-direction: row;
    align-items: center;

    svg {
      display: none;
    }
  }

  .best-run__profit-value {
    font-size: 1.8rem;
  }
}
</style>
