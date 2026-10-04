<script lang="ts">
export default {
  name: "LocationSystemCard",
};
</script>

<script lang="ts" setup>
import SystemStrip from "@/frontend/components/Locations/SystemStrip/index.vue";
import SystemCardSkeleton from "@/frontend/components/Locations/SystemCard/Skeleton.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Location,
  type LocationJumpPoint,
  useLocationTree,
} from "@/services/fyApi";

type Props = {
  system: Location;
  // Shown by name beside the title. A jump point that leads to another listed
  // system is marked out from one that leads off the page.
  jumpPoints?: LocationJumpPoint[];
  // Connections with no jump point at this end yet, by the other system's
  // name: listed beside the jump points, without a page to link to.
  unlinked?: string[];
};

const props = withDefaults(defineProps<Props>(), {
  jumpPoints: () => [],
  unlinked: () => [],
});

const { t } = useI18n();

const {
  data: tree,
  isError,
  refetch,
} = useLocationTree(computed(() => props.system.slug));

// The panel under the title, whichever state it is in: what lines drawn
// between cards start and end on.
const body = ref<HTMLElement | null>(null);

defineExpose({ body });
</script>

<template>
  <div class="location-system-card">
    <div class="location-system-card__head">
      <router-link
        :to="{ name: 'location', params: { slug: system.slug } }"
        class="location-system-card__title"
      >
        {{ system.name }}
      </router-link>
      <div
        v-if="jumpPoints.length || unlinked.length"
        class="location-system-card__jump-points"
        data-test="system-jump-points"
      >
        <span class="location-system-card__caption">
          {{ t("labels.location.jumpPoints") }}
        </span>
        <router-link
          v-for="jumpPoint in jumpPoints"
          :key="jumpPoint.location.id"
          :to="{ name: 'location', params: { slug: jumpPoint.location.slug } }"
          :title="jumpPoint.location.name ?? undefined"
          class="location-system-card__jump-point"
          :class="{
            'location-system-card__jump-point--listed':
              jumpPoint.destinationSystemId,
            'location-system-card__jump-point--temporary': jumpPoint.temporary,
          }"
        >
          {{ jumpPoint.destinationName }}
        </router-link>
        <span
          v-for="name in unlinked"
          :key="name"
          class="location-system-card__jump-point location-system-card__jump-point--unlinked"
          data-test="system-unlinked-jump"
        >
          {{ name }}
        </span>
      </div>
    </div>
    <div ref="body">
      <SystemStrip v-if="tree" :tree="tree" compact />
      <p v-else-if="isError" class="location-system-card__error">
        {{ t("labels.location.systemUnavailable") }}
        <Btn @click="() => refetch()">{{ t("actions.retry") }}</Btn>
      </p>
      <SystemCardSkeleton v-else :with-title="false" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.location-system-card {
  display: flex;
  flex-direction: column;
  gap: 8px;

  &__head {
    display: flex;
    flex-wrap: wrap;
    align-items: baseline;
    justify-content: space-between;
    gap: 8px 16px;
  }

  &__title {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 16px;
    color: var(--color-text, #c8c8c8);
  }

  &__jump-points {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 6px;
  }

  &__caption {
    margin-right: 2px;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
  }

  &__jump-point {
    padding: 2px 8px;
    font-size: 12px;
    color: var(--color-text-dim, #959595);
    border: 1px dashed var(--color-edge-soft, rgb(122 130 136 / 0.45));
    border-radius: var(--radius-control-bare, 6px);

    &:hover {
      color: var(--color-text, #c8c8c8);
    }

    &--listed {
      color: var(--color-text, #c8c8c8);
      border-style: solid;
      border-color: var(--color-primary, #428bca);

      &:hover {
        color: #fff;
      }
    }

    // In the game, on a record meant for another tunnel: dotted like its line.
    &--temporary {
      border-style: dotted;
    }

    // A connection with no jump point to go to yet: dashed like its line.
    &--unlinked,
    &--unlinked:hover {
      color: var(--color-text-dim, #959595);
      border-color: var(--color-primary, #428bca);
    }
  }

  &__error {
    display: flex;
    align-items: center;
    gap: 8px;
    margin: 0;
    font-size: 13px;
    color: var(--color-text-dim, #959595);
  }
}
</style>
