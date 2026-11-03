<script lang="ts">
export default {
  name: "PickerCard",
};
</script>

<script lang="ts" setup>
import PanelBgImage from "@/shared/components/base/Panel/BgImage/index.vue";

export type PickerCardBadge = {
  key: string;
  label: string;
  primary?: boolean;
};

type Props = {
  name: string;
  subtitle?: string;
  image?: string;
  // `contain` for a render on a transparent ground, which `cover` would crop.
  imageFit?: "cover" | "contain";
  badges?: PickerCardBadge[];
  selected?: boolean;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  subtitle: undefined,
  image: undefined,
  imageFit: "cover",
  badges: () => [],
  selected: false,
  disabled: false,
});

const emit = defineEmits<{
  toggle: [];
}>();

// The toggle is an empty overlay, so its name has to carry everything the card
// shows visually - including the badges, which are decoration to a screen reader.
const accessibleName = computed(() =>
  [props.name, props.subtitle, ...props.badges.map((badge) => badge.label)]
    .filter(Boolean)
    .join(", "),
);
</script>

<template>
  <div
    class="picker-card"
    :class="{
      'picker-card--selected': selected,
      'picker-card--disabled': disabled,
    }"
  >
    <div class="picker-card__image">
      <img
        v-if="image && imageFit === 'contain'"
        :src="image"
        alt=""
        class="picker-card__render"
        loading="lazy"
      />
      <PanelBgImage v-else-if="image" :image="image" />
      <div v-else-if="$slots.placeholder" class="picker-card__placeholder">
        <slot name="placeholder" />
      </div>

      <div v-if="badges.length" class="picker-card__badges">
        <span
          v-for="badge in badges"
          :key="badge.key"
          class="picker-card__badge"
          :class="{ 'picker-card__badge--primary': badge.primary }"
        >
          {{ badge.label }}
        </span>
      </div>

      <div class="picker-card__check" aria-hidden="true">
        <i class="fa-regular fa-check" />
      </div>

      <!--
        Controls of the card's own, such as a quantity stepper: a sibling of the
        toggle rather than a child, since a button may not contain buttons.
      -->
      <slot name="overlay" />
    </div>

    <div class="picker-card__meta">
      <span class="picker-card__name">{{ name }}</span>
      <span v-if="subtitle" class="picker-card__subtitle">{{ subtitle }}</span>
    </div>

    <button
      type="button"
      class="picker-card__toggle"
      :aria-pressed="selected"
      :aria-label="accessibleName"
      :disabled="disabled"
      @click="emit('toggle')"
    />
  </div>
</template>

<style scoped>
@reference "../../../entrypoints/tailwind.css";

/*
 * A card in a picker grid: `panel--slim`'s geometry (one hairline, the
 * smaller radius, no end-caps) because a grid of repeated cards is the case that
 * variant exists for, but its own component rather than a Panel because the
 * whole card has to be one toggle.
 *
 * The toggle is a transparent overlay stretched over the card instead of the
 * card's wrapper element. The alternative - a <button> wrapping the contents -
 * cannot hold the quantity stepper, and the stepper has to sit inside the card:
 * its own row would make every selected card taller than its neighbours and
 * reflow the grid on each click.
 */
.picker-card {
  @apply relative flex flex-col overflow-hidden;
  @apply bg-control border-edge-soft rounded-surface-slim border;
  @apply transition-[background-color,border-color] duration-150 ease-in-out;
}

.picker-card:hover {
  @apply bg-control-hover border-edge;
}

/* Already in the list you are picking for. Still readable - the badge says why -
   but out of reach, so the count of what you are about to add stays honest. */
.picker-card--disabled {
  @apply opacity-45;
}

.picker-card--disabled:hover {
  @apply bg-control border-edge-soft;
}

.picker-card--disabled .picker-card__toggle {
  @apply cursor-default;
}

.picker-card--selected {
  @apply border-primary;
  background-color: rgb(66 139 202 / 0.18);
}

.picker-card--selected:hover {
  background-color: rgb(66 139 202 / 0.28);
}

/* ---------- toggle overlay ---------- */
.picker-card__toggle {
  @apply absolute inset-0 z-[1] m-0 cursor-pointer border-0 bg-transparent p-0;
}

.picker-card__toggle:focus-visible {
  @apply outline-primary rounded-surface-slim outline-2;
  outline-offset: -3px;
}

/* The containing block PanelBgImage's absolute fill resolves against. */
.picker-card__image {
  @apply relative w-full;
  aspect-ratio: 16 / 9;
}

/* What stands in for a missing picture: an icon, centred and quiet. */
.picker-card__placeholder {
  @apply text-muted absolute inset-0 flex items-center justify-center;
  font-size: 2.5rem;
}

/* An item render on a transparent ground, which cropping as a store image is
   cropped would cut into. */
.picker-card__render {
  @apply absolute inset-0 h-full w-full;
  object-fit: contain;
  padding: 8px;
}

/* ---------- selection tick ----------
   Kept in the DOM at every state so selecting a card cannot reflow it; scaled to
   nothing until it is earned. */
.picker-card__check {
  @apply pointer-events-none absolute z-[2] flex items-center justify-center;
  @apply bg-primary rounded-full text-[11px] text-white opacity-0;
  @apply transition-[opacity,transform] duration-150 ease-in-out;
  top: 8px;
  right: 8px;
  width: 22px;
  height: 22px;
  transform: scale(0.6);
}

.picker-card--selected .picker-card__check {
  @apply opacity-100;
  transform: scale(1);
}

/* ---------- already-have markers ---------- */
.picker-card__badges {
  @apply pointer-events-none absolute z-[2] flex flex-col items-start gap-1;
  top: 8px;
  left: 8px;
}

.picker-card__badge {
  @apply rounded-control-bare text-[11px] leading-none whitespace-nowrap;
  @apply bg-gray-black/80 text-gray-lighter;
  padding: 4px 6px;
}

/* Gold, the token the app already uses for "notable about *your* copy" - and a
   dark glyph on it, because at 11px a tint this saturated is the only step that
   stays legible against the store image behind it. */
.picker-card__badge--primary {
  background-color: rgb(212 175 55 / 0.9);
  color: #222;
}

/* ---------- meta ---------- */
.picker-card__meta {
  @apply flex min-w-0 flex-col gap-1;
  padding: 8px 10px 10px;
}

.picker-card__name {
  @apply text-lifted truncate text-[15px] leading-tight font-semibold;
}

.picker-card__subtitle {
  @apply text-muted truncate text-[12px] leading-tight;
}

@media (prefers-reduced-motion: reduce) {
  .picker-card,
  .picker-card__check {
    transition-duration: 1ms;
  }
}
</style>
