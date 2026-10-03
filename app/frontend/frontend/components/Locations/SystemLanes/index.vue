<script lang="ts">
export default {
  name: "LocationSystemLanes",
};
</script>

<script lang="ts" setup>
import { useResizeObserver } from "@vueuse/core";
import SystemCard from "@/frontend/components/Locations/SystemCard/index.vue";
import type { Location, LocationJumpPoint } from "@/services/fyApi";
import { jumpConnections, jumpExits, jumpLaneLayout } from "./layout";

type Props = {
  systems: Location[];
  jumpPoints: LocationJumpPoint[];
};

const props = defineProps<Props>();

// Lines need room between the system's name and the jump points listed beside
// it. Narrower than this, or with more columns than fit, every jump point is
// listed on its card instead.
const MIN_WIDTH = 768;
const MAX_COLUMNS = 6;
const COLUMN_SPACING = 112;
// The columns sit between these shares of the width: clear of the name on
// the left and of the jump points listed on the right.
const FIRST_COLUMN = 0.32;
const LAST_COLUMN = 0.7;
// A label sits on its line just past the dot: half the dot, a 4px gap, half
// the label.
const LABEL_OFFSET = 7 + 4 + 11;

type Anchor = { top: number; bottom: number };

const container = ref<HTMLElement | null>(null);
const width = ref(0);
const anchors = ref<Record<string, Anchor>>({});
const cards = new Map<string, { body: HTMLElement | null }>();

const systemIds = computed(() => props.systems.map((system) => system.id));

const connections = computed(() =>
  jumpConnections(systemIds.value, props.jumpPoints),
);

const layout = computed(() =>
  jumpLaneLayout(systemIds.value, connections.value),
);

const columnX = (column: number) =>
  width.value * FIRST_COLUMN + column * COLUMN_SPACING;

const hasLanes = computed(
  () =>
    connections.value.length > 0 &&
    layout.value.columns <= MAX_COLUMNS &&
    width.value >= MIN_WIDTH &&
    columnX(layout.value.columns - 1) <= width.value * LAST_COLUMN,
);

const orderedSystems = computed(() => {
  if (!hasLanes.value) {
    return props.systems;
  }

  const byId = new Map(props.systems.map((system) => [system.id, system]));

  return layout.value.order.flatMap((id) => byId.get(id) ?? []);
});

const exits = computed(() => jumpExits(systemIds.value, props.jumpPoints));

const jumpPointsOf = (system: Location) =>
  hasLanes.value
    ? (exits.value[system.id] ?? [])
    : props.jumpPoints.filter((jumpPoint) => jumpPoint.systemId === system.id);

const setCard = (id: string, card: unknown) => {
  if (card) {
    cards.set(id, card as { body: HTMLElement | null });
  } else {
    cards.delete(id);
  }
};

const measure = () => {
  const box = container.value?.getBoundingClientRect();

  if (!box) {
    return;
  }

  width.value = box.width;

  const next: Record<string, Anchor> = {};

  cards.forEach((card, id) => {
    const rect = card.body?.getBoundingClientRect();

    if (rect) {
      next[id] = { top: rect.top - box.top, bottom: rect.bottom - box.top };
    }
  });

  anchors.value = next;
};

useResizeObserver(container, measure);

onMounted(measure);

watch(orderedSystems, () => nextTick(measure));

const lanes = computed(() => {
  if (!hasLanes.value) {
    return [];
  }

  const { order } = layout.value;

  return layout.value.lanes.flatMap((lane) => {
    const upperId = order[lane.upper];
    const lowerId = order[lane.lower];
    const upper = anchors.value[upperId];
    const lower = anchors.value[lowerId];

    if (!upper || !lower) {
      return [];
    }

    const x = columnX(lane.column);
    const leaving = lane.connection.ends[upperId];
    const arriving = lane.connection.ends[lowerId];

    const ends = [
      leaving && {
        key: `${lane.connection.key}:leaving`,
        jumpPoint: leaving,
        icon: "fa-arrow-down",
        y: upper.bottom,
        labelY: upper.bottom + LABEL_OFFSET,
      },
      arriving && {
        key: `${lane.connection.key}:arriving`,
        jumpPoint: arriving,
        icon: "fa-arrow-up",
        y: lower.top,
        labelY: lower.top - LABEL_OFFSET,
      },
    ].filter((end) => !!end);

    return [
      {
        key: lane.connection.key,
        x,
        top: upper.bottom,
        bottom: lower.top,
        ends,
      },
    ];
  });
});
</script>

<template>
  <div
    ref="container"
    class="location-lanes"
    :class="{ 'location-lanes--drawn': hasLanes }"
  >
    <svg
      v-if="lanes.length"
      class="location-lanes__lines"
      aria-hidden="true"
      data-test="jump-lanes"
    >
      <line
        v-for="lane in lanes"
        :key="lane.key"
        :x1="lane.x"
        :x2="lane.x"
        :y1="lane.top"
        :y2="lane.bottom"
      />
    </svg>

    <SystemCard
      v-for="system in orderedSystems"
      :key="system.id"
      :ref="(card) => setCard(system.id, card)"
      :system="system"
      :jump-points="jumpPointsOf(system)"
      class="location-lanes__card"
    />

    <template v-for="lane in lanes" :key="lane.key">
      <template v-for="end in lane.ends" :key="end.key">
        <span
          class="location-lanes__dot"
          :style="{ left: `${lane.x}px`, top: `${end.y}px` }"
          aria-hidden="true"
        />
        <router-link
          :to="{
            name: 'location',
            params: { slug: end.jumpPoint.location.slug },
          }"
          :aria-label="end.jumpPoint.location.name ?? undefined"
          :title="end.jumpPoint.location.name ?? undefined"
          class="location-lanes__label"
          :style="{ left: `${lane.x}px`, top: `${end.labelY}px` }"
          data-test="jump-lane-label"
        >
          <i class="fa-light" :class="end.icon" aria-hidden="true" />
          {{ end.jumpPoint.destinationName }}
        </router-link>
      </template>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.location-lanes {
  position: relative;
  isolation: isolate;
  display: flex;
  flex-direction: column;
  gap: 16px;

  &--drawn {
    gap: 96px;
  }

  &__lines {
    position: absolute;
    inset: 0;
    z-index: 0;
    width: 100%;
    height: 100%;
    overflow: visible;
    pointer-events: none;

    line {
      stroke: var(--color-primary, #428bca);
      stroke-width: 2;
      stroke-linecap: round;
      filter: drop-shadow(
        0 0 4px
          color-mix(in srgb, var(--color-primary, #428bca) 60%, transparent)
      );
    }
  }

  // Above the lines, so a line that passes a card runs under its panel.
  &__card {
    position: relative;
    z-index: 1;
  }

  &__dot,
  &__label {
    position: absolute;
    z-index: 2;
    transform: translate(-50%, -50%);
  }

  // The ring a lit body gets on the strip, at a jump point's size.
  &__dot {
    width: 12px;
    height: 12px;
    background: var(--color-primary, #428bca);
    border-radius: 50%;
    box-shadow: 0 0 0 3px rgb(66 139 202 / 0.25);
    pointer-events: none;
  }

  // The strip's own caption type, on a badge like the location page's.
  &__label {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    height: 22px;
    padding: 0 8px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    white-space: nowrap;
    color: var(--color-text, #c8c8c8);
    background: #1d2329;
    border: 1px solid var(--color-primary, #428bca);
    border-radius: var(--radius-control-bare, 6px);

    i {
      color: var(--color-primary, #428bca);
    }

    &:hover,
    &:focus-visible {
      color: #fff;
    }
  }
}
</style>
