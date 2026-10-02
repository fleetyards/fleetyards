<script lang="ts">
export default {
  name: "LocationContentsList",
};
</script>

<script lang="ts" setup>
import LocationKindIcon from "@/frontend/components/Locations/KindIcon/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type LocationContentsEntry,
  type LocationContentsGroup,
} from "@/services/fyApi";

type Props = {
  groups: LocationContentsGroup[];
  parentId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

// Hurston holds 65 outposts directly. A group opens on its first dozen and
// the rest are one click away, so a body page stays a page.
const COLLAPSED_LIMIT = 12;

const expanded = ref<Record<string, boolean>>({});

const visible = (group: LocationContentsGroup) =>
  expanded.value[group.kind]
    ? group.entries
    : group.entries.slice(0, COLLAPSED_LIMIT);

const toggle = (group: LocationContentsGroup) => {
  expanded.value = {
    ...expanded.value,
    [group.kind]: !expanded.value[group.kind],
  };
};

// A name several places share opens the list of all of them; a single place
// opens its own page.
const target = (entry: LocationContentsEntry) =>
  entry.count > 1
    ? {
        name: "locations-places",
        query: { parentIdEq: props.parentId, nameIn: [entry.name ?? ""] },
      }
    : { name: "location", params: { slug: entry.location.slug } };
</script>

<template>
  <div class="location-contents">
    <section
      v-for="group in groups"
      :key="group.kind"
      class="location-contents__group"
    >
      <h2 class="location-contents__title">
        <LocationKindIcon :kind="group.kind" />
        {{ t(`labels.location.kinds.${group.kind}`) }} · {{ group.count }}
      </h2>

      <ul class="location-contents__grid">
        <li v-for="entry in visible(group)" :key="entry.location.id">
          <router-link :to="target(entry)" class="location-contents__tile">
            <span class="location-contents__name">{{ entry.name }}</span>
            <span v-if="entry.count > 1" class="location-contents__count">
              {{ t("labels.location.namesakes", { count: entry.count }) }}
            </span>
            <span
              v-if="!entry.shownOnStarmap"
              class="location-contents__hidden"
              :title="t('labels.location.hiddenOnStarmap')"
            >
              <i class="fa-duotone fa-eye-slash" aria-hidden="true" />
              <span class="sr-only">
                {{ t("labels.location.hiddenOnStarmap") }}
              </span>
            </span>
          </router-link>
        </li>
      </ul>

      <button
        v-if="group.entries.length > COLLAPSED_LIMIT"
        type="button"
        class="location-contents__more"
        :aria-expanded="!!expanded[group.kind]"
        @click="toggle(group)"
      >
        {{
          expanded[group.kind]
            ? t("labels.location.showFewer")
            : t("labels.location.showAll", { count: group.entries.length })
        }}
      </button>
    </section>
  </div>
</template>

<style lang="scss" scoped>
.location-contents {
  display: flex;
  flex-direction: column;
  gap: 18px;

  &__group {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  &__title {
    display: flex;
    align-items: center;
    gap: 10px;
    margin: 0;
    padding: 0 2px;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 13px;
    font-weight: 500;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim, #959595);

    .location-kind-icon {
      font-size: 20px;
      color: var(--color-muted, #7a8288);
    }
  }

  &__grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 6px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__tile {
    display: flex;
    align-items: center;
    gap: 8px;
    min-height: 44px;
    padding: 8px 12px;
    background-color: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    border-radius: 8px;
    color: var(--color-text, #c8c8c8);
    transition:
      border-color 150ms ease,
      color 150ms ease;

    &:hover,
    &:focus-visible {
      border-color: var(--color-primary, #428bca);
      color: #fff;
    }
  }

  &__name {
    flex-grow: 1;
    min-width: 0;
    overflow: hidden;
    font-size: 14px;
    font-weight: 600;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__count {
    padding: 1px 7px;
    font-size: 12px;
    font-weight: 600;
    background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
    border-radius: 4px;
  }

  &__hidden {
    color: var(--color-muted, #7a8288);
  }

  &__more {
    align-self: flex-start;
    min-height: 32px;
    padding: 0 12px;
    background: transparent;
    border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
    border-radius: 6px;
    color: var(--color-text, #c8c8c8);
    font: inherit;
    font-size: 13px;
    cursor: pointer;
  }
}
</style>
