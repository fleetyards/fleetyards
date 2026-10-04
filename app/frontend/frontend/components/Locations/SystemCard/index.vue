<script lang="ts">
export default {
  name: "LocationSystemCard",
};
</script>

<script lang="ts" setup>
import SystemStrip from "@/frontend/components/Locations/SystemStrip/index.vue";
import SystemCardSkeleton from "@/frontend/components/Locations/SystemCard/Skeleton.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import type {
  JumpChip,
  JumpStyle,
} from "@/frontend/components/Locations/SystemLanes/layout";
import { useI18n } from "@/shared/composables/useI18n";
import { type Location, useLocationTree } from "@/services/fyApi";

type Props = {
  system: Location;
  // Listed by name beside the title, bordered like the line each stands for:
  // solid, dotted, dashed, or a quiet dashed one for a way off the page.
  chips?: JumpChip[];
};

const props = withDefaults(defineProps<Props>(), {
  chips: () => [],
});

const STYLE_CLASSES: Record<JumpStyle, string> = {
  inGame: "location-system-card__jump-point--in-game",
  temporary: "location-system-card__jump-point--temporary",
  planned: "location-system-card__jump-point--planned",
};

const chipClass = (chip: JumpChip) => chip.style && STYLE_CLASSES[chip.style];

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
        v-if="chips.length"
        class="location-system-card__jump-points"
        data-test="system-jump-points"
      >
        <span class="location-system-card__caption">
          {{ t("labels.location.jumpPoints") }}
        </span>
        <template v-for="chip in chips" :key="chip.key">
          <router-link
            v-if="chip.jumpPoint"
            :to="{
              name: 'location',
              params: { slug: chip.jumpPoint.location.slug },
            }"
            :title="chip.jumpPoint.location.name ?? undefined"
            class="location-system-card__jump-point"
            :class="chipClass(chip)"
          >
            {{ chip.name }}
          </router-link>
          <span
            v-else
            class="location-system-card__jump-point location-system-card__jump-point--unlinked"
            :class="chipClass(chip)"
            data-test="system-unlinked-jump"
          >
            {{ chip.name }}
          </span>
        </template>
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

    &--in-game,
    &--temporary,
    &--planned {
      color: var(--color-text, #c8c8c8);
      border-color: var(--color-primary, #428bca);

      &:hover {
        color: #fff;
      }
    }

    &--in-game {
      border-style: solid;
    }

    &--temporary {
      border-style: dotted;
    }

    // No jump point at this end to go to, so nothing to answer a hover.
    &--unlinked,
    &--unlinked:hover {
      color: var(--color-text-dim, #959595);
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
