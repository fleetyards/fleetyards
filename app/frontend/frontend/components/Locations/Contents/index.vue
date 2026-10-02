<script lang="ts">
export default {
  name: "LocationContentsList",
};
</script>

<script lang="ts" setup>
import RowListItem from "@/shared/components/RowListItem/index.vue";
import {
  type RowListItemBadge,
  type RowListItemChip,
} from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type LocationContentsEntry,
  type LocationContentsGroup,
} from "@/services/fyApi";
import { LOCATION_KIND_ICONS } from "@/frontend/components/Locations/kinds";

type Props = {
  groups: LocationContentsGroup[];
  parentId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

// A name several places share opens the list of all of them; a single place
// opens its own page.
const target = (entry: LocationContentsEntry) =>
  entry.count > 1
    ? {
        name: "locations",
        query: { parentIdEq: props.parentId, nameIn: [entry.name ?? ""] },
      }
    : { name: "location", params: { slug: entry.location.slug } };

const chips = (entry: LocationContentsEntry): RowListItemChip[] =>
  entry.count > 1
    ? [
        {
          key: "count",
          label: t("labels.location.namesakes", { count: entry.count }),
        },
      ]
    : [];

const badges = (entry: LocationContentsEntry): RowListItemBadge[] =>
  entry.shownOnStarmap
    ? []
    : [
        {
          key: "hidden",
          value: t("labels.location.hiddenOnStarmap"),
          quiet: true,
        },
      ];
</script>

<template>
  <div class="location-contents">
    <section
      v-for="group in groups"
      :key="group.kind"
      class="location-contents__group"
    >
      <h2 class="location-contents__title">
        <i :class="LOCATION_KIND_ICONS[group.kind]" aria-hidden="true" />
        {{ t(`labels.location.kinds.${group.kind}`) }} · {{ group.count }}
      </h2>
      <ul class="location-contents__list">
        <li v-for="entry in group.entries" :key="entry.location.id">
          <RowListItem
            :to="target(entry)"
            :chips="chips(entry)"
            :badges="badges(entry)"
          >
            <template #name>{{ entry.name }}</template>
          </RowListItem>
        </li>
      </ul>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.location-contents {
  display: flex;
  flex-direction: column;
  gap: 20px;

  &__group {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  &__title {
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 0;
    padding: 0 2px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 11px;
    font-weight: 500;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim, #959595);

    i {
      color: var(--color-muted, #7a8288);
    }
  }

  &__list {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin: 0;
    padding: 0;
    list-style: none;
  }
}
</style>
