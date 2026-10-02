<script lang="ts">
export default {
  name: "LocationResources",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type LocationResourceGroup } from "@/services/fyApi";

type Props = {
  groups: LocationResourceGroup[];
};

defineProps<Props>();

const { t, tExists } = useI18n();

// The export may head a section nobody has seen yet; it still reads as words.
const kindLabel = (kind: string) => {
  const key = `labels.location.resourceKinds.${kind}`;

  return tExists(key) ? t(key) : kind.replaceAll("_", " ");
};
</script>

<template>
  <section class="location-resources">
    <div
      v-for="group in groups"
      :key="group.kind"
      class="location-resources__group"
    >
      <span class="location-resources__kind">{{ kindLabel(group.kind) }}</span>

      <ul class="location-resources__items">
        <li v-for="item in group.items" :key="item.name">
          <router-link
            v-if="item.commodity"
            :to="{ name: 'commodity', params: { slug: item.commodity.slug } }"
            class="location-resources__item location-resources__item--link"
          >
            {{ item.name }}
            <span v-if="item.note" class="location-resources__note">
              {{ item.note }}
            </span>
          </router-link>
          <span v-else class="location-resources__item">
            {{ item.name }}
            <span v-if="item.note" class="location-resources__note">
              {{ item.note }}
            </span>
          </span>
        </li>
      </ul>
    </div>
  </section>
</template>

<style lang="scss" scoped>
// Inside a metrics card, which draws the frame and the title.
.location-resources {
  display: flex;
  flex-direction: column;
  gap: 12px;

  &__kind {
    margin: 0;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 11px;
    font-weight: 500;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: var(--color-text-dim, #959595);
  }

  &__group {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  &__kind {
    letter-spacing: 0.12em;
    color: var(--color-muted, #7a8288);
  }

  &__items {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__item {
    display: inline-flex;
    align-items: baseline;
    gap: 6px;
    padding: 3px 9px;
    font-size: 12px;
    font-weight: 600;
    color: var(--color-text, #c8c8c8);
    background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
    border: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
    border-radius: 4px;

    &--link:hover,
    &--link:focus-visible {
      border-color: var(--color-primary, #428bca);
      color: #fff;
    }
  }

  &__note {
    font-weight: 400;
    color: var(--color-text-dim, #959595);
  }
}
</style>
