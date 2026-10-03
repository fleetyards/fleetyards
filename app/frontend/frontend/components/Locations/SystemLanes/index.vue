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
import PlaceholderCard from "./PlaceholderCard.vue";
import {
  PLACEHOLDER_SYSTEMS,
  type PlaceholderSystem,
  placeholderDestination,
} from "./placeholders";

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

type Entry =
  | { id: string; name: string; system: Location; placeholder?: undefined }
  | {
      id: string;
      name: string;
      system?: undefined;
      placeholder: PlaceholderSystem;
    };

const placeholders = computed(() =>
  PLACEHOLDER_SYSTEMS.filter(
    (placeholder) =>
      !props.systems.some((system) => system.name === placeholder.name),
  ),
);

// By name, the order the systems arrive in, so a placeholder takes the place
// the system will have once it is in the game.
const entries = computed<Entry[]>(() =>
  [
    ...props.systems.map((system) => ({
      id: system.id,
      name: system.name ?? "",
      system,
    })),
    ...placeholders.value.map((placeholder) => ({
      id: placeholder.id,
      name: placeholder.name,
      placeholder,
    })),
  ].sort((a, b) => a.name.localeCompare(b.name)),
);

const systemIds = computed(() => entries.value.map((entry) => entry.id));

// A jump point into a placeholder names it but has no id to point at.
const jumpPoints = computed(() => {
  const placeholderIds = new Map(
    placeholders.value.map((placeholder) => [
      placeholderDestination(placeholder),
      placeholder.id,
    ]),
  );

  return props.jumpPoints.map((jumpPoint) =>
    jumpPoint.destinationSystemId
      ? jumpPoint
      : {
          ...jumpPoint,
          destinationSystemId:
            placeholderIds.get(jumpPoint.destinationName.toLowerCase()) ?? null,
        },
  );
});

// The name jump points use for a system: "Nyx" for the Nyx System.
const shortName = (entry: Entry) =>
  entry.placeholder
    ? entry.placeholder.star.name
    : (entry.system.name ?? "").replace(/ System$/, "");

const plannedConnections = computed(() => {
  const idsByName = new Map(
    entries.value.map((entry) => [shortName(entry).toLowerCase(), entry.id]),
  );

  return placeholders.value.flatMap((placeholder) =>
    placeholder.jumpsTo.flatMap((name) => {
      const otherId = idsByName.get(name.toLowerCase());

      if (!otherId) {
        return [];
      }

      const pair = [placeholder.id, otherId].sort() as [string, string];

      return [
        { key: pair.join(":"), systemIds: pair, ends: {}, planned: true },
      ];
    }),
  );
});

// A jump point in the game files outranks an announced connection.
const connections = computed(() => {
  const found = jumpConnections(systemIds.value, jumpPoints.value);
  const keys = new Set(found.map((connection) => connection.key));

  return [
    ...found,
    ...plannedConnections.value.filter(
      (connection) => !keys.has(connection.key),
    ),
  ];
});

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

const orderedEntries = computed(() => {
  if (!hasLanes.value) {
    return entries.value;
  }

  const byId = new Map(entries.value.map((entry) => [entry.id, entry]));

  return layout.value.order.flatMap((id) => byId.get(id) ?? []);
});

const exits = computed(() => jumpExits(systemIds.value, jumpPoints.value));

const jumpPointsOf = (system: Location) =>
  hasLanes.value
    ? (exits.value[system.id] ?? [])
    : jumpPoints.value.filter((jumpPoint) => jumpPoint.systemId === system.id);

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

watch(orderedEntries, () => nextTick(measure));

const lanes = computed(() => {
  if (!hasLanes.value) {
    return [];
  }

  const { order } = layout.value;
  const names = new Map(
    entries.value.map((entry) => [entry.id, shortName(entry)]),
  );

  return layout.value.lanes.flatMap((lane) => {
    const upperId = order[lane.upper];
    const lowerId = order[lane.lower];
    const upper = anchors.value[upperId];
    const lower = anchors.value[lowerId];

    if (!upper || !lower) {
      return [];
    }

    const x = columnX(lane.column);
    const { planned } = lane.connection;
    const leaving = lane.connection.ends[upperId];
    const arriving = lane.connection.ends[lowerId];

    // A planned connection has no jump point to link to, so both ends are
    // labelled with the name of the other system alone.
    const ends = [
      (leaving || planned) && {
        key: `${lane.connection.key}:leaving`,
        jumpPoint: leaving,
        name: leaving?.destinationName ?? names.get(lowerId),
        icon: "fa-arrow-down",
        y: upper.bottom,
        labelY: upper.bottom + LABEL_OFFSET,
      },
      (arriving || planned) && {
        key: `${lane.connection.key}:arriving`,
        jumpPoint: arriving,
        name: arriving?.destinationName ?? names.get(upperId),
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
        planned,
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
        :class="{ 'location-lanes__line--planned': lane.planned }"
      />
    </svg>

    <template v-for="entry in orderedEntries" :key="entry.id">
      <SystemCard
        v-if="entry.system"
        :ref="(card) => setCard(entry.id, card)"
        :system="entry.system"
        :jump-points="jumpPointsOf(entry.system)"
        class="location-lanes__card"
      />
      <PlaceholderCard
        v-else
        :ref="(card) => setCard(entry.id, card)"
        :system="entry.placeholder"
        class="location-lanes__card"
      />
    </template>

    <template v-for="lane in lanes" :key="lane.key">
      <template v-for="end in lane.ends" :key="end.key">
        <template v-if="end.jumpPoint">
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
            {{ end.name }}
          </router-link>
        </template>
        <span
          v-else
          class="location-lanes__label location-lanes__label--planned"
          :style="{ left: `${lane.x}px`, top: `${end.labelY}px` }"
          data-test="jump-lane-planned"
        >
          <i class="fa-light" :class="end.icon" aria-hidden="true" />
          {{ end.name }}
        </span>
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

    .location-lanes__line--planned {
      stroke-dasharray: 6 6;
      filter: none;
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

    &--planned {
      color: var(--color-text-dim, #959595);
      border-style: dashed;
    }

    &:hover,
    &:focus-visible {
      color: #fff;
    }
  }
}
</style>
