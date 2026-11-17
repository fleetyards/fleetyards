<script lang="ts">
export default {
  name: "StarmapPanel",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
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

  for (const list of map.values()) {
    list.sort((a, b) =>
      a.role === b.role
        ? (a.distance ?? 0) - (b.distance ?? 0) || a.name.localeCompare(b.name)
        : a.rank - b.rank,
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

// The tree as rows: the star, then its planets with the open one unfolded
// into its moons and places, and so on down.
const rows = computed(() => {
  const list: { entry: StarmapItem; depth: number; count: number }[] = [];

  const walk = (entry: StarmapItem, depth: number) => {
    const children = childrenOf.value.get(entry.key) ?? [];
    list.push({ entry, depth, count: children.length });

    if (depth > 0 && !open.value.has(entry.key)) return;

    for (const child of children) {
      // Around the star only its bodies are listed; the rest is a search
      // away, or unfolds with the body it belongs to.
      if (entry.role === "star" && child.role === "place") continue;
      walk(child, depth + 1);
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

const pick = (entry: StarmapItem) => {
  emit("focus", entry);
};

const ICONS: Record<string, string> = {
  star: "fa-duotone fa-sun",
  planet: "fa-duotone fa-earth-americas",
  moon: "fa-duotone fa-moon",
  system: "fa-duotone fa-galaxy",
};
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
          @click="pick(entry)"
        >
          <i
            :class="ICONS[entry.role] ?? 'fa-duotone fa-location-dot'"
            aria-hidden="true"
          />
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

    <ul v-else class="starmap-panel__list" data-test="starmap-tree">
      <li v-for="row in rows" :key="row.entry.key">
        <button
          type="button"
          class="starmap-panel__row"
          :class="{ 'starmap-panel__row--current': row.entry.key === focusKey }"
          :style="{ paddingLeft: `${8 + row.depth * 14}px` }"
          :aria-current="row.entry.key === focusKey ? 'true' : undefined"
          @click="pick(row.entry)"
        >
          <i
            :class="ICONS[row.entry.role] ?? 'fa-duotone fa-location-dot'"
            aria-hidden="true"
          />
          <span class="starmap-panel__name">{{ row.entry.name }}</span>
          <span
            v-if="row.count && row.entry.role !== 'star'"
            class="starmap-panel__meta"
          >
            {{ row.count }}
          </span>
        </button>
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
.starmap-panel {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-height: 0;
  height: 100%;

  &__search {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 6px 10px;
    border: 1px solid rgb(90 175 212 / 30%);
    border-radius: var(--radius-control);
    background: rgb(255 255 255 / 4%);
    color: rgb(255 255 255 / 60%);

    input {
      flex: 1;
      min-width: 0;
      border: 0;
      background: none;
      color: #fff;
      font-size: 0.8125rem;
      outline: none;
    }
  }

  &__list {
    flex: 1;
    min-height: 0;
    margin: 0;
    padding: 0;
    overflow-y: auto;
    list-style: none;
  }

  &__row {
    display: flex;
    align-items: center;
    gap: 8px;
    width: 100%;
    padding: 5px 8px;
    border: 0;
    border-radius: var(--radius-control);
    background: none;
    color: rgb(255 255 255 / 75%);
    font-size: 0.8125rem;
    text-align: left;
    cursor: pointer;

    i {
      width: 14px;
      color: rgb(90 175 212 / 80%);
    }

    &:hover {
      background: rgb(255 255 255 / 6%);
      color: #fff;
    }

    &--current {
      background: rgb(90 175 212 / 16%);
      color: #fff;
    }
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
    color: rgb(255 255 255 / 45%);
  }

  &__empty {
    padding: 8px;
    font-size: 0.8125rem;
    color: rgb(255 255 255 / 50%);
  }
}
</style>
