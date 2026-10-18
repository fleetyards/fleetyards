<script lang="ts">
export default {
  name: "HardpointItemWrapper",
};
</script>

<script lang="ts" setup>
import { useResizeObserver } from "@vueuse/core";
import HardpointQuantity from "@/frontend/components/Models/Hardpoints/Quantity/index.vue";

type Props = {
  count?: number;
  intended?: boolean;
};

withDefaults(defineProps<Props>(), {
  count: undefined,
  intended: false,
});

const inner = ref<HTMLElement>();

const content = ref<HTMLElement>();

const rail = ref<HTMLElement>();

// Where the rail sits while it is part of the row, kept for when it is not.
const railBox = ref({ top: 0, right: 0, room: 0 });

const wrapped = ref(false);

/**
 * Whether the gold headline went to a line of its own. The rail then sits over
 * the first line only, so the headline can reach the row's edge; the first
 * line keeps the room the rail took, so the switch never changes what wraps.
 */
const measure = () => {
  const row = inner.value;
  const items = content.value;
  const controls = rail.value;
  if (!row || !items || !controls) {
    wrapped.value = false;
    return;
  }

  if (!wrapped.value) {
    railBox.value = {
      top: controls.offsetTop,
      right: row.clientWidth - controls.offsetLeft - controls.offsetWidth,
      // Its width and the gap before it: what the lines beside it lacked.
      room:
        controls.offsetWidth +
        (parseFloat(getComputedStyle(row).columnGap) || 0),
    };
  }

  const first = items.firstElementChild as HTMLElement | null;
  const headline = items.querySelector<HTMLElement>(
    ":scope > .hardpoint-headline",
  );

  wrapped.value =
    !!first &&
    !!headline &&
    headline !== first &&
    headline.offsetTop >= first.offsetTop + first.offsetHeight;
};

useResizeObserver(inner, measure);

onMounted(measure);

const wrappedStyle = computed(() =>
  wrapped.value
    ? {
        "--hardpoint-rail-top": `${railBox.value.top}px`,
        "--hardpoint-rail-right": `${railBox.value.right}px`,
        "--hardpoint-rail-room": `${railBox.value.room}px`,
      }
    : undefined,
);
</script>

<template>
  <div class="hardpoint-item">
    <div class="hardpoint-item__wrapper">
      <div
        ref="inner"
        class="hardpoint-item__inner"
        :class="{ 'hardpoint-item__inner--wrapped': wrapped }"
        :style="wrappedStyle"
      >
        <div ref="content" class="hardpoint-item__content">
          <slot name="default" />
        </div>
        <div
          v-if="(count && count > 1) || $slots.actions"
          ref="rail"
          class="hardpoint-item__rail"
        >
          <HardpointQuantity
            v-if="count && count > 1"
            :quantity="count"
            tag="span"
            class="hardpoint-item__count"
          />
          <slot name="actions" />
        </div>
      </div>
      <slot name="loadout" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
