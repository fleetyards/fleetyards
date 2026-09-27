<script lang="ts">
export default {
  name: "TradeRoutesRunRow",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useTradeRouteFormat } from "@/frontend/composables/useTradeRouteFormat";
import { type TradeRoute } from "@/services/fyApi";

type Props = {
  route: TradeRoute;
  rank: number;
  // The largest figure in the list, which the profit bar is drawn against.
  topValue: number;
};

const props = defineProps<Props>();

const { t } = useI18n();

const currentRoute = useRoute();

const { figure, location, pricesAge, limitLabel } = useTradeRouteFormat();

const hasShip = computed(() => props.route.loadableScu != null);

const value = computed(() =>
  hasShip.value ? (props.route.profitPerRun ?? 0) : props.route.profitPerScu,
);

const barWidth = computed(() =>
  props.topValue > 0
    ? `${Math.max(2, Math.round((value.value / props.topValue) * 100))}%`
    : "0%",
);

// Every destination for this purchase, ungrouped.
const othersLink = computed(() => ({
  name: currentRoute.name as string,
  query: {
    ...currentRoute.query,
    commodity: props.route.commodity.slug,
    origin: props.route.originTerminal.id,
  },
}));
</script>

<template>
  <div class="run-row" role="row">
    <span class="run-row__rank" role="cell">{{ rank }}</span>

    <span class="run-row__commodity" role="cell">
      <router-link
        class="run-row__name"
        :to="{ name: 'commodity', params: { slug: route.commodity.slug } }"
      >
        {{ route.commodity.name }}
      </router-link>
      <router-link
        v-if="route.otherDestinations"
        class="run-row__others"
        :to="othersLink"
      >
        {{
          t("labels.tradeRoutes.otherBuyers", {
            count: route.otherDestinations,
          })
        }}
      </router-link>
    </span>

    <span class="run-row__legs" role="cell">
      <span class="run-row__leg">
        <span class="run-row__terminal">{{ route.originTerminal.name }}</span>
        <span class="run-row__where">{{ location(route.originTerminal) }}</span>
      </span>
      <i
        class="fa-light fa-arrow-right run-row__arrow"
        :aria-label="t('labels.tradeRoutes.to')"
      />
      <span class="run-row__leg">
        <span class="run-row__terminal">{{
          route.destinationTerminal.name
        }}</span>
        <span class="run-row__where">{{
          location(route.destinationTerminal)
        }}</span>
      </span>
    </span>

    <span v-if="hasShip" class="run-row__load" role="cell">
      <span>{{
        t("labels.tradeRoutes.scu", { count: route.loadableScu ?? 0 })
      }}</span>
      <span :class="`run-row__limit run-row__limit--${route.loadLimit}`">
        {{ limitLabel(route) }}
      </span>
    </span>

    <span v-if="hasShip" class="run-row__spend" role="cell">
      {{ figure(route.investment) }}
    </span>

    <span class="run-row__distance" role="cell">
      <template v-if="route.distance != null">
        {{ t("labels.tradeRoutes.distanceValue", { count: route.distance }) }}
      </template>
    </span>

    <span class="run-row__age" role="cell">{{ pricesAge(route) }}</span>

    <span class="run-row__profit" role="cell">
      <span class="run-row__profit-value">+{{ figure(value) }}</span>
      <span class="run-row__bar"><span :style="{ width: barWidth }" /></span>
    </span>
  </div>
</template>

<style lang="scss" scoped>
.run-row {
  display: grid;
  grid-template-columns: var(--run-row-columns);
  align-items: center;
  gap: 16px;
  padding: 14px 20px;
  border-bottom: 1px solid $gray-darker;
}

.run-row__rank {
  color: var(--color-text-dim, #959595);
  font-family: Orbitron, sans-serif;
}

.run-row__commodity,
.run-row__leg,
.run-row__load {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.run-row__name {
  color: #fff;
  font-weight: 600;
}

.run-row__others,
.run-row__where,
.run-row__limit {
  font-size: 0.8rem;
}

.run-row__where,
.run-row__age {
  color: var(--color-text-dim, #959595);
}

.run-row__legs {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.run-row__terminal {
  overflow: hidden;
  color: #fff;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.run-row__arrow {
  flex-shrink: 0;
  color: var(--color-muted, #7a8288);
}

.run-row__limit--hold {
  color: var(--color-text-dim, #959595);
}

.run-row__limit--stock,
.run-row__limit--demand {
  color: #e0a15c;
}

.run-row__limit--budget {
  color: #b9a3e3;
}

.run-row__profit {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
}

.run-row__profit-value {
  color: var(--color-success-tint, #6fcf6f);
  font-size: 1rem;
  font-weight: 700;
  white-space: nowrap;
}

.run-row__bar {
  display: flex;
  justify-content: flex-end;
  width: 100%;
  max-width: 160px;
  height: 4px;
  overflow: hidden;
  border-radius: 2px;
  background: $gray-darker;

  span {
    display: block;
    height: 100%;
    background: var(--color-success, #5cb85c);
  }
}

@media (max-width: $desktop-breakpoint) {
  .run-row {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    gap: 6px 14px;
    padding: 14px 16px;
  }

  .run-row__rank,
  .run-row__bar {
    display: none;
  }

  .run-row__commodity {
    flex: 1 1 55%;
  }

  .run-row__profit {
    flex: 0 0 auto;
  }

  .run-row__legs {
    flex: 1 1 100%;
    flex-direction: column;
    align-items: flex-start;
    gap: 2px;
  }

  .run-row__arrow {
    transform: rotate(90deg);
  }

  .run-row__load {
    flex-direction: row;
    gap: 6px;
  }

  .run-row__load,
  .run-row__spend,
  .run-row__distance,
  .run-row__age {
    font-size: 0.85rem;
  }
}
</style>
