<script lang="ts">
export default {
  name: "HangarPlannerRouteChain",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { RouteChainNode } from "@/frontend/components/Hangar/Planner/RouteChain/types";

type Props = {
  nodes: RouteChainNode[];
  // The ship the route still has to reach, drawn as an empty stop at the end.
  pending?: string;
  // Stops stacked top to bottom, for a narrow column.
  vertical?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  pending: undefined,
  vertical: false,
});

const { t } = useI18n();

const lastIndex = computed(() => props.nodes.length - 1);
</script>

<template>
  <ol
    class="route-chain"
    :class="{ 'route-chain--vertical': vertical }"
    :aria-label="t('hangarPlanner.routes')"
  >
    <li
      v-for="(node, index) in nodes"
      :key="node.key"
      class="route-chain__item"
    >
      <div v-if="node.link" class="route-chain__link">
        <span class="route-chain__source">{{ node.link.source }}</span>
        <span class="route-chain__line" aria-hidden="true">
          <i class="fa-solid fa-chevron-right" />
        </span>
        <span v-if="node.link.price" class="route-chain__price">
          {{ node.link.price }}
        </span>
      </div>
      <div
        class="route-chain__node"
        :class="{
          'route-chain__node--target': !pending && index === lastIndex,
        }"
      >
        <span class="route-chain__kind">{{ node.kind }}</span>
        <span class="route-chain__ship">{{ node.ship }}</span>
        <span v-if="node.price" class="route-chain__price">
          {{ node.price }}
        </span>
        <span v-if="node.missing" class="route-chain__missing">
          <i class="fa-duotone fa-triangle-exclamation" />
          {{ t("hangarPlanner.sourceMissing") }}
        </span>
      </div>
    </li>
    <li v-if="pending" class="route-chain__item">
      <div v-if="nodes.length" class="route-chain__link">
        <span class="route-chain__line" aria-hidden="true">
          <i class="fa-solid fa-chevron-right" />
        </span>
      </div>
      <div class="route-chain__node route-chain__node--pending">
        <span class="route-chain__kind">
          {{ t("hangarPlanner.route.stillToReach") }}
        </span>
        <span class="route-chain__ship">{{ pending }}</span>
      </div>
    </li>
  </ol>
</template>

<style lang="scss" scoped>
.route-chain {
  display: flex;
  flex-wrap: wrap;
  row-gap: 10px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.route-chain__item {
  display: flex;
  align-items: stretch;
}

.route-chain__node {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 140px;
  padding: 8px 12px;
  border: 1px solid var(--color-edge);
  border-radius: 8px;
  background: var(--color-control);
}

.route-chain__node--target {
  border-color: var(--color-primary);
}

.route-chain__node--pending {
  border-style: dashed;
  background: transparent;

  .route-chain__ship {
    color: var(--color-text);
  }
}

.route-chain__kind,
.route-chain__source {
  font-size: 0.75rem;
  color: var(--color-text-dim);
}

.route-chain__ship {
  font-weight: 600;
  color: var(--color-lifted);
}

.route-chain__price {
  font-size: 0.8rem;
  white-space: nowrap;
}

.route-chain__missing {
  font-size: 0.75rem;
  color: var(--color-warning);
}

.route-chain__link {
  display: flex;
  flex-direction: column;
  gap: 2px;
  align-items: center;
  justify-content: center;
  min-width: 88px;
  padding: 0 8px;

  .route-chain__price {
    font-weight: 600;
    color: var(--color-lifted);
  }
}

.route-chain__line {
  display: flex;
  align-items: center;
  width: 100%;
  color: var(--color-muted);

  &::before {
    content: "";
    flex: 1;
    height: 1px;
    background: var(--color-edge);
  }

  i {
    margin-left: -2px;
    font-size: 0.6rem;
  }
}

@mixin stacked {
  &,
  .route-chain__item {
    flex-direction: column;
  }

  .route-chain__link {
    flex-direction: row;
    justify-content: flex-start;
    gap: 8px;
    min-height: 32px;
    margin-left: 12px;
    padding: 0 0 0 18px;
    border-left: 1px solid var(--color-edge);
  }

  .route-chain__line {
    display: none;
  }
}

.route-chain--vertical {
  @include stacked;
}

@media (max-width: 575px) {
  .route-chain {
    @include stacked;
  }
}
</style>
