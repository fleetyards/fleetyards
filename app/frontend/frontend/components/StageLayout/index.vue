<script lang="ts">
export default {
  name: "StageLayout",
};
</script>

<script lang="ts" setup>
type Props = {
  // What stands on the stage, which sets its shape on a phone: a standing
  // figure is portrait, a ship landscape.
  landscape?: boolean;
  controlsLabel?: string;
};

withDefaults(defineProps<Props>(), {
  landscape: false,
  controlsLabel: undefined,
});

const slots = useSlots();
</script>

<template>
  <div
    class="stage-layout"
    :class="{
      'stage-layout--landscape': landscape,
      'stage-layout--with-start': !!slots.start,
    }"
  >
    <div class="stage-layout__stage">
      <slot />
    </div>

    <div
      v-if="slots.controls"
      class="stage-layout__controls"
      role="toolbar"
      :aria-label="controlsLabel"
    >
      <slot name="controls" />
    </div>

    <div v-if="slots.start" class="stage-layout__column stage-layout__start">
      <slot name="start" />
    </div>

    <div v-if="slots.end" class="stage-layout__column stage-layout__end">
      <slot name="end" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
// One cell holds the stage and, over its foot, the control bar; the columns
// follow below it on a phone and float over it on a larger screen.
.stage-layout {
  display: grid;
  grid-template-areas:
    "stage"
    "start"
    "end";
  grid-template-columns: minmax(0, 1fr);
  gap: 1rem;

  @media (min-width: $desktop-breakpoint) {
    grid-template-areas:
      ". . end"
      "controls controls controls";
    grid-template-columns:
      0
      minmax(0, 1fr)
      minmax(17rem, 23rem);
    grid-template-rows: minmax(0, 1fr) auto;
    // Down to the foot of the screen, below the heading above it.
    height: max(36rem, calc(100dvh - 12rem));
    padding: 1rem;
  }
}

.stage-layout--with-start {
  @media (min-width: $desktop-breakpoint) {
    grid-template-areas:
      "start . end"
      "controls controls controls";
    grid-template-columns:
      minmax(17rem, 21rem)
      minmax(0, 1fr)
      minmax(17rem, 23rem);
  }
}

// Portrait on a phone, as a standing figure is: a landscape stage would leave
// most of itself empty either side of it.
.stage-layout__stage {
  position: relative;
  grid-area: stage;
  height: min(70vh, 44rem);
  min-height: 24rem;
  overflow: hidden;
  border: 1px solid var(--color-edge-faint);
  border-radius: var(--radius-surface);
  // Lit by a spot behind what stands there and a glow on the floor under it.
  background:
    radial-gradient(
      ellipse 42% 12% at 50% 90%,
      rgba($primary, 0.28),
      transparent 70%
    ),
    radial-gradient(
      ellipse 55% 60% at 50% 42%,
      rgba($primary, 0.16),
      rgba($background, 0.35) 70%,
      transparent 100%
    );

  // Behind the whole layout, the columns and bar over it.
  @media (min-width: $desktop-breakpoint) {
    grid-area: 1 / 1 / -1 / -1;
    height: auto;
    margin: -1rem;
  }
}

.stage-layout--landscape .stage-layout__stage {
  height: min(45vh, 40rem);
  min-height: 20rem;

  @media (min-width: $desktop-breakpoint) {
    height: auto;
  }
}

.stage-layout__controls {
  z-index: 1;
  display: flex;
  flex-wrap: wrap;
  grid-area: stage;
  align-items: center;
  align-self: end;
  justify-content: center;
  justify-self: center;
  gap: 0.5rem;
  margin: 0.75rem;
  padding: 0.5rem;
  border: 1px solid var(--color-edge-soft);
  border-radius: var(--radius-surface-slim);
  background: rgb(26 29 33 / 0.8);
  backdrop-filter: blur(8px);

  @media (min-width: $desktop-breakpoint) {
    flex-wrap: nowrap;
    grid-area: controls;
    max-width: 100%;
    margin: 0;
  }
}

.stage-layout__column {
  z-index: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  min-height: 0;

  // Room for the first and last panel's end-caps, which sit on their edge.
  @media (min-width: $desktop-breakpoint) {
    padding-block: 1px;
    overflow-y: auto;
  }
}

.stage-layout__start {
  grid-area: start;
}

.stage-layout__end {
  grid-area: end;

  // Clear of the viewer's own buttons in the stage's lower corner.
  @media (min-width: $desktop-breakpoint) {
    align-self: start;
    max-height: min(60dvh, 100%);
  }
}
</style>
