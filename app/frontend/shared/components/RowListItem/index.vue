<script lang="ts">
export default {
  name: "RowListItem",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import {
  type RowListItemBadge,
  type RowListItemChip,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";

type Props = {
  /**
   * Where the name links to. A record the game never named has no slug and so
   * no route, and `router-link` throws on a missing required param rather than
   * rendering nothing -- which took a whole catalogue list down once. The name
   * is plain text when this is absent.
   */
  to?: RouteLocationRaw;
  chips?: RowListItemChip[];
  chipsMax?: number;
  tags?: RowListItemTag[];
  badges?: RowListItemBadge[];
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  chips: () => [],
  chipsMax: 4,
  tags: () => [],
  badges: () => [],
});

const shownChips = computed(() => props.chips.slice(0, props.chipsMax));

const extraChips = computed(() =>
  Math.max(props.chips.length - props.chipsMax, 0),
);
</script>

<template>
  <!-- A container, not one big link. The row holds links of its own -- every
       value the catalogue can be narrowed by is a link that narrows it -- and
       an anchor inside an anchor is invalid and does not work. The name is the
       way to the record instead. -->
  <div class="row-list-item">
    <slot name="leading" />

    <span class="row-list-item__main">
      <router-link v-if="to" class="row-list-item__name" :to="to">
        <slot name="name" />
      </router-link>
      <span v-else class="row-list-item__name">
        <slot name="name" />
      </span>

      <span class="row-list-item__sub">
        <slot name="sub" />
      </span>
    </span>

    <!-- Capped with a count for the rest, so a patch that doubles what a record
         is made of cannot grow the row past one line. The `+N` sits inside the
         run rather than after it: it is one of the things being counted. -->
    <span v-if="shownChips.length" class="row-list-item__chips">
      <component
        :is="chip.to ? 'router-link' : 'span'"
        v-for="chip in shownChips"
        :key="chip.key"
        class="row-list-item__chip"
        :to="chip.to"
      >
        {{ chip.label }}
      </component>
      <span v-if="extraChips" class="row-list-item__chip-more">
        +{{ extraChips }}
      </span>
    </span>

    <slot />

    <!-- Coloured words rather than filled pills, and a link each, like every
         other value on the row the catalogue can be narrowed by. -->
    <span v-if="tags.length" class="row-list-item__tags">
      <component
        :is="tag.to ? 'router-link' : 'span'"
        v-for="tag in tags"
        :key="tag.key"
        class="row-list-item__tag"
        :class="`row-list-item__tag--${tag.tone || 'default'}`"
        :to="tag.to"
      >
        {{ tag.label }}
      </component>
    </span>

    <!-- Labelled, because a row has no column heading above it to say which
         figure a bare "1" or "A" is. -->
    <span v-if="badges.length" class="row-list-item__badges">
      <span
        v-for="badge in badges"
        :key="badge.key"
        class="row-list-item__badge"
        :class="{ 'row-list-item__badge--quiet': badge.quiet }"
      >
        <span v-if="badge.label" class="row-list-item__badge-label">
          {{ badge.label }}
        </span>
        <span class="row-list-item__badge-value">{{ badge.value }}</span>
      </span>
    </span>

    <!-- Last, where a row's action sits everywhere else in the app, and outside
         the badges: it is the one thing here that is not a fact about the
         record. -->
    <span v-if="$slots.actions" class="row-list-item__actions">
      <slot name="actions" />
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
