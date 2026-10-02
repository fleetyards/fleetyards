<script lang="ts">
export default {
  name: "LocationKindCounts",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type LocationKindCount } from "@/services/fyApi";
import {
  LOCATION_KIND_ICONS,
  LOCATION_KIND_ORDER,
} from "@/frontend/components/Locations/kinds";

type Props = {
  counts: LocationKindCount[];
};

const props = defineProps<Props>();

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
      <i :class="LOCATION_KIND_ICONS[entry.kind]" aria-hidden="true" />
      <span class="sr-only">{{
        t(`labels.location.kinds.${entry.kind}`)
      }}</span>
      {{ entry.count }}
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

  &__item {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    font-size: 12px;
    color: var(--color-text-dim, #959595);

    i {
      color: var(--color-muted, #7a8288);
    }
  }
}
</style>
