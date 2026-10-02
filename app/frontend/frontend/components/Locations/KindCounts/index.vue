<script lang="ts">
export default {
  name: "LocationKindCounts",
};
</script>

<script lang="ts" setup>
import LocationKindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type LocationKindCount } from "@/services/fyApi";
import { LOCATION_KIND_ORDER } from "@/frontend/components/Locations/kinds";

type Props = {
  counts: LocationKindCount[];
  // The place the counted ones sit in. With it, each count opens the list of
  // them: Nyx's 306 QV Logistics Stations are a number until it does.
  parentId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  parentId: undefined,
});

const { t } = useI18n();

const sorted = computed(() =>
  [...props.counts].sort(
    (a, b) =>
      LOCATION_KIND_ORDER.indexOf(a.kind) - LOCATION_KIND_ORDER.indexOf(b.kind),
  ),
);
</script>

<template>
  <ul v-if="sorted.length" class="location-kind-counts">
    <li
      v-for="entry in sorted"
      :key="entry.kind"
      class="location-kind-counts__item"
      :title="t(`labels.location.kinds.${entry.kind}`)"
    >
      <component
        :is="parentId ? 'router-link' : 'span'"
        class="location-kind-counts__entry"
        :to="
          parentId
            ? {
                name: 'locations-places',
                query: { parentIdEq: parentId, kindEq: entry.kind },
              }
            : undefined
        "
      >
        <LocationKindIcon :kind="entry.kind" />
        <span class="sr-only">{{
          t(`labels.location.kinds.${entry.kind}`)
        }}</span>
        {{ entry.count }}
      </component>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
.location-kind-counts {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 10px;
  margin: 0;
  padding: 0;
  list-style: none;

  &__item,
  &__entry {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    font-size: 13px;
    color: var(--color-text-dim, #959595);
  }

  &__item {
    .location-kind-icon {
      font-size: 17px;
      color: var(--color-muted, #7a8288);
    }
  }

  a.location-kind-counts__entry:hover {
    color: #fff;
  }
}
</style>
