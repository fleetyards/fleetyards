<script lang="ts">
export default {
  name: "StarmapPanel",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import KindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import { LOCATION_KIND_ORDER } from "@/frontend/components/Locations/kinds";
import type { LocationKindEnum } from "@/services/fyApi";
import type { StarmapItem } from "./layout";

type Props = {
  items: StarmapItem[];
  focusKey: string | null;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  focus: [item: StarmapItem];
}>();

const { t } = useI18n();

const search = ref("");

const RESULTS = 30;

const byKey = computed(
  () => new Map(props.items.map((entry) => [entry.key, entry])),
);

const childrenOf = computed(() => {
  const map = new Map<string, StarmapItem[]>();

  for (const entry of props.items) {
    if (!entry.anchor) continue;
    const list = map.get(entry.anchor) ?? [];
    list.push(entry);
    map.set(entry.anchor, list);
  }

  // Moons before places, then nearest first.
  for (const list of map.values()) {
    list.sort(
      (a, b) =>
        a.rank - b.rank ||
        (a.distance ?? 0) - (b.distance ?? 0) ||
        a.name.localeCompare(b.name),
    );
  }

  return map;
});

const roots = computed(() => props.items.filter((entry) => !entry.anchor));

// The bodies the focus sits in, which the tree keeps open.
const open = computed(() => {
  const keys = new Set<string>();
  let current = props.focusKey ? byKey.value.get(props.focusKey) : undefined;

  while (current) {
    keys.add(current.key);
    current = current.anchor ? byKey.value.get(current.anchor) : undefined;
  }

  return keys;
});

// Which kind groups the reader unfolded, by body and kind.
const unfolded = ref(new Set<string>());

const groupKey = (body: string, kind: LocationKindEnum) => `${body}:${kind}`;

const toggleGroup = (key: string) => {
  const next = new Set(unfolded.value);
  if (next.has(key)) next.delete(key);
  else next.add(key);
  unfolded.value = next;
};

type Row =
  | {
      type: "item";
      key: string;
      entry: StarmapItem;
      depth: number;
      count: number;
    }
  | {
      type: "group";
      key: string;
      kind: LocationKindEnum;
      depth: number;
      count: number;
      expanded: boolean;
    };

const kindOrder = (kind: LocationKindEnum) => LOCATION_KIND_ORDER.indexOf(kind);

// The tree as rows: the star with its planets, an open body unfolded into its
// moons and then its places, folded by kind -- Hurston alone has eighty.
const rows = computed(() => {
  const list: Row[] = [];

  const walk = (entry: StarmapItem, depth: number) => {
    const children = childrenOf.value.get(entry.key) ?? [];
    const bodies = children.filter((child) => child.role !== "place");
    const places = children.filter((child) => child.role === "place");

    list.push({
      type: "item",
      key: entry.key,
      entry,
      depth,
      count: entry.role === "star" ? 0 : children.length,
    });

    if (entry.role !== "star" && depth > 0 && !open.value.has(entry.key)) {
      return;
    }

    for (const body of bodies) walk(body, depth + 1);

    // Around the star only its bodies are listed; the rest is a search away.
    if (entry.role === "star") return;

    const kinds = [...new Set(places.map((place) => place.kind))].sort(
      (a, b) => kindOrder(a) - kindOrder(b),
    );

    for (const kind of kinds) {
      const members = places.filter((place) => place.kind === kind);
      const key = groupKey(entry.key, kind);
      const expanded =
        unfolded.value.has(key) ||
        members.some((member) => member.key === props.focusKey);

      list.push({
        type: "group",
        key,
        kind,
        depth: depth + 1,
        count: members.length,
        expanded,
      });

      if (expanded) {
        for (const member of members) {
          list.push({
            type: "item",
            key: member.key,
            entry: member,
            depth: depth + 2,
            count: 0,
          });
        }
      }
    }
  };

  for (const root of roots.value) walk(root, 0);

  return list;
});

const results = computed(() => {
  const query = search.value.trim().toLowerCase();
  if (!query) return [];

  return props.items
    .filter((entry) => entry.name.toLowerCase().includes(query))
    .sort(
      (a, b) =>
        Number(!a.name.toLowerCase().startsWith(query)) -
          Number(!b.name.toLowerCase().startsWith(query)) ||
        a.rank - b.rank ||
        a.name.localeCompare(b.name),
    )
    .slice(0, RESULTS);
});

const anchorName = (entry: StarmapItem) =>
  entry.anchor ? byKey.value.get(entry.anchor)?.name : undefined;

const isBody = (entry: StarmapItem) =>
  entry.role === "star" ||
  entry.role === "planet" ||
  entry.role === "moon" ||
  entry.role === "system";

const dotStyle = (entry: StarmapItem) => ({ "--dot-color": entry.color });

const indent = (depth: number) => ({ paddingLeft: `${10 + depth * 16}px` });
</script>

<template>
  <div class="starmap-panel">
    <label class="starmap-panel__search">
      <i class="fa-light fa-magnifying-glass" aria-hidden="true" />
      <span class="sr-only">{{ t("starmap.search") }}</span>
      <input
        v-model="search"
        type="search"
        :placeholder="t('starmap.search')"
        data-test="starmap-search"
        @keydown.escape.stop="search = ''"
      />
    </label>

    <ul
      v-if="search.trim()"
      class="starmap-panel__list"
      data-test="starmap-results"
    >
      <li v-for="entry in results" :key="entry.key">
        <button
          type="button"
          class="starmap-panel__row"
          :class="{ 'starmap-panel__row--current': entry.key === focusKey }"
          @click="emit('focus', entry)"
        >
          <span
            v-if="isBody(entry)"
            class="starmap-panel__dot"
            :style="dotStyle(entry)"
          />
          <KindIcon v-else class="starmap-panel__glyph" :kind="entry.kind" />
          <span class="starmap-panel__name">{{ entry.name }}</span>
          <span v-if="anchorName(entry)" class="starmap-panel__meta">
            {{ anchorName(entry) }}
          </span>
        </button>
      </li>
      <li v-if="!results.length" class="starmap-panel__empty">
        {{ t("starmap.noMatches") }}
      </li>
    </ul>

    <template v-else>
      <span class="starmap-panel__heading">{{ t("starmap.bodies") }}</span>
      <TransitionGroup
        tag="ul"
        name="starmap-row"
        class="starmap-panel__list"
        data-test="starmap-tree"
      >
        <li v-for="row in rows" :key="row.key" class="starmap-panel__item">
          <button
            v-if="row.type === 'item'"
            type="button"
            class="starmap-panel__row"
            :class="{
              'starmap-panel__row--current': row.entry.key === focusKey,
              'starmap-panel__row--minor': row.entry.role === 'place',
            }"
            :style="indent(row.depth)"
            :aria-current="row.entry.key === focusKey ? 'true' : undefined"
            @click="emit('focus', row.entry)"
          >
            <span
              v-if="isBody(row.entry)"
              class="starmap-panel__dot"
              :class="{
                'starmap-panel__dot--small': row.entry.role === 'moon',
              }"
              :style="dotStyle(row.entry)"
            />
            <KindIcon
              v-else
              class="starmap-panel__glyph"
              :kind="row.entry.kind"
            />
            <span class="starmap-panel__name">{{ row.entry.name }}</span>
            <span v-if="row.count" class="starmap-panel__meta">
              {{ row.count }}
            </span>
          </button>
          <button
            v-else
            type="button"
            class="starmap-panel__row starmap-panel__row--group"
            :style="indent(row.depth)"
            :aria-expanded="row.expanded"
            @click="toggleGroup(row.key)"
          >
            <KindIcon class="starmap-panel__glyph" :kind="row.kind" />
            <span class="starmap-panel__name">
              {{ t(`starmap.groups.${row.kind}`) }}
            </span>
            <span class="starmap-panel__meta">{{ row.count }}</span>
            <i
              class="fa-light fa-chevron-down starmap-panel__chevron"
              :class="{ 'starmap-panel__chevron--open': row.expanded }"
              aria-hidden="true"
            />
          </button>
        </li>
      </TransitionGroup>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.starmap-panel {
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 0;
  flex: 1;

  &__search {
    display: flex;
    align-items: center;
    gap: 10px;
    height: 43px;
    padding: 0 12px;
    border: 1px solid var(--color-edge);
    border-radius: var(--radius-control);
    background: var(--color-field);
    color: var(--color-text-dim);

    &:focus-within {
      border-color: var(--color-primary);
    }

    input {
      flex: 1;
      min-width: 0;
      border: 0;
      background: none;
      color: var(--color-lifted);
      font-size: 0.875rem;
      outline: none;
    }
  }

  &__heading {
    font-family: Orbitron, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim);
  }

  &__list {
    display: flex;
    flex: 1;
    flex-direction: column;
    gap: 2px;
    min-height: 0;
    margin: 0;
    padding: 0;
    overflow-y: auto;
    list-style: none;
  }

  &__row {
    display: flex;
    align-items: center;
    gap: 10px;
    width: 100%;
    min-height: 36px;
    padding: 0 10px;
    border: 1px solid transparent;
    border-radius: var(--radius-control-inner);
    background: none;
    color: var(--color-text);
    font-size: 0.84375rem;
    text-align: left;
    cursor: pointer;

    &:hover {
      background: var(--color-control-hover);
      color: var(--color-lifted);
    }

    &:focus-visible {
      outline: 2px solid var(--color-primary);
      outline-offset: -2px;
    }

    // Selection is marked by its frame, as everywhere else in the app.
    &--current,
    &--current:hover {
      border-color: var(--color-primary);
      background: rgb(66 139 202 / 14%);
      color: #fff;
    }

    &--minor,
    &--group {
      color: var(--color-text-dim);
    }
  }

  &__dot {
    flex-shrink: 0;
    width: 11px;
    height: 11px;
    border-radius: 50%;
    background:
      radial-gradient(
        circle at 32% 28%,
        rgb(255 255 255 / 45%) 0%,
        rgb(255 255 255 / 0%) 40%,
        rgb(0 0 0 / 55%) 100%
      ),
      var(--dot-color);

    &--small {
      width: 8px;
      height: 8px;
      margin-inline: 1.5px;
    }
  }

  &__glyph {
    flex-shrink: 0;
    width: 12px;
    font-size: 12px;
    color: var(--color-muted);
  }

  &__name {
    flex: 1;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__meta {
    flex-shrink: 0;
    font-size: 0.6875rem;
    color: var(--color-text-dim);
  }

  &__chevron {
    flex-shrink: 0;
    font-size: 0.625rem;
    color: var(--color-muted);
    transition: transform 0.15s ease;

    &--open {
      transform: rotate(180deg);
    }
  }

  &__item {
    max-height: 40px;
  }

  &__empty {
    padding: 8px;
    font-size: 0.8125rem;
    color: var(--color-text-dim);
  }
}

// Rows unfold and fold rather than appear: a body opened in the tree slides
// its moons and places in, and the rail grows with them.
.starmap-row-enter-active,
.starmap-row-leave-active {
  overflow: hidden;
  transition:
    max-height 0.22s ease,
    opacity 0.18s ease;
}

.starmap-row-enter-from,
.starmap-row-leave-to {
  max-height: 0;
  opacity: 0;
}

@media (prefers-reduced-motion: reduce) {
  .starmap-row-enter-active,
  .starmap-row-leave-active {
    transition: none;
  }
}
</style>
