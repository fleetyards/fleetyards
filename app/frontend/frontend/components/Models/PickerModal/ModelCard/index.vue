<script lang="ts">
export default {
  name: "ModelPickerCard",
};
</script>

<script lang="ts" setup>
import PanelBgImage from "@/shared/components/base/Panel/BgImage/index.vue";
import { type ModelOption } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useWebpCheck } from "@/shared/composables/useWebpCheck";
import fallbackImageJpg from "@/images/fallback/store_image.jpg";
import fallbackImage from "@/images/fallback/store_image.webp";
import type { ModelPickerBadge } from "@/frontend/components/Models/PickerModal/types";

type Props = {
  option: ModelOption;
  selected?: boolean;
  quantity?: number;
  quantities?: boolean;
  highlight?: `${ModelPickerBadge}`;
  note?: string;
  disabled?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  selected: false,
  quantity: 1,
  quantities: false,
  highlight: undefined,
  note: undefined,
  disabled: false,
});

const emit = defineEmits<{
  toggle: [];
  increase: [];
  decrease: [];
}>();

const { t } = useI18n();

const { supported: webpSupported } = useWebpCheck();

const image = computed(() => {
  const storeImage = props.option.media.storeImage;

  if (storeImage?.mediumUrl) {
    return storeImage.mediumUrl;
  }

  return webpSupported.value ? fallbackImage : fallbackImageJpg;
});

const subtitle = computed(() =>
  [props.option.manufacturer.name, props.option.classificationLabel]
    .filter(Boolean)
    .join(" · "),
);

/**
 * The flag matching the list you opened the picker from leads, because that is
 * the duplicate you are about to create; the other one is context worth having
 * (a wishlisted ship you are now buying) rather than a warning. A note names why
 * the card cannot be picked, which outranks both.
 */
const badges = computed(() => {
  // Which flag leads is a property of the flag, not of where it lands in the
  // list: keyed on position, a wishlisted ship shown in the *hangar* picker got
  // the loud tint purely by being the only badge on the card.
  const flags = [
    { key: "inHangar", set: props.option.inHangar },
    { key: "onWishlist", set: props.option.onWishlist },
  ]
    .filter((badge) => badge.set)
    .map((badge) => ({
      key: badge.key,
      label: t(`modelPicker.badges.${badge.key}`),
      primary: badge.key === props.highlight,
    }))
    .sort((a, b) => Number(b.primary) - Number(a.primary));

  if (!props.note) {
    return flags;
  }

  return [{ key: "note", label: props.note, primary: true }, ...flags];
});

// The toggle is an empty overlay, so its name has to carry everything the card
// shows visually - including the badges, which are decoration to a screen reader.
const accessibleName = computed(() =>
  [
    props.option.name,
    subtitle.value,
    ...badges.value.map((badge) => badge.label),
  ]
    .filter(Boolean)
    .join(", "),
);
</script>

<template>
  <div
    class="model-card"
    :class="{
      'model-card--selected': selected,
      'model-card--disabled': disabled,
    }"
    :data-test="`model-picker-card-${option.slug}`"
  >
    <div class="model-card__image">
      <PanelBgImage :image="image" />

      <div v-if="badges.length" class="model-card__badges">
        <span
          v-for="badge in badges"
          :key="badge.key"
          class="model-card__badge"
          :class="{ 'model-card__badge--primary': badge.primary }"
        >
          {{ badge.label }}
        </span>
      </div>

      <div class="model-card__check" aria-hidden="true">
        <i class="fa-regular fa-check" />
      </div>

      <!--
        A sibling of the toggle rather than a child: the toggle is a button, and
        a button may not contain buttons. Both are absolutely placed in this
        region, with the stepper stacked above so its clicks are its own.
      -->
      <div v-if="quantities && selected" class="model-card__quantity">
        <button
          type="button"
          class="model-card__step"
          :disabled="quantity <= 1"
          :aria-label="t('modelPicker.actions.decrease', { name: option.name })"
          @click="emit('decrease')"
        >
          <i class="fa-regular fa-minus" />
        </button>
        <span class="model-card__count">{{ quantity }}</span>
        <button
          type="button"
          class="model-card__step"
          :aria-label="t('modelPicker.actions.increase', { name: option.name })"
          @click="emit('increase')"
        >
          <i class="fa-regular fa-plus" />
        </button>
      </div>
    </div>

    <div class="model-card__meta">
      <span class="model-card__name">{{ option.name }}</span>
      <span v-if="subtitle" class="model-card__subtitle">{{ subtitle }}</span>
    </div>

    <button
      type="button"
      class="model-card__toggle"
      :aria-pressed="selected"
      :aria-label="accessibleName"
      :disabled="disabled"
      @click="emit('toggle')"
    />
  </div>
</template>

<style scoped>
@reference "../../../../../entrypoints/tailwind.css";

/*
 * A picker card, not a ship card: `panel--slim`'s geometry (one hairline, the
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
.model-card {
  @apply relative flex flex-col overflow-hidden;
  @apply bg-control border-edge-soft rounded-surface-slim border;
  @apply transition-[background-color,border-color] duration-150 ease-in-out;
}

.model-card:hover {
  @apply bg-control-hover border-edge;
}

/* Already in the list you are picking for. Still readable - the badge says why -
   but out of reach, so the count of what you are about to add stays honest. */
.model-card--disabled {
  @apply opacity-45;
}

.model-card--disabled:hover {
  @apply bg-control border-edge-soft;
}

.model-card--disabled .model-card__toggle {
  @apply cursor-default;
}

.model-card--selected {
  @apply border-primary;
  background-color: rgb(66 139 202 / 0.18);
}

.model-card--selected:hover {
  background-color: rgb(66 139 202 / 0.28);
}

/* ---------- toggle overlay ---------- */
.model-card__toggle {
  @apply absolute inset-0 z-[1] m-0 cursor-pointer border-0 bg-transparent p-0;
}

.model-card__toggle:focus-visible {
  @apply outline-primary rounded-surface-slim outline-2;
  outline-offset: -3px;
}

/* The containing block PanelBgImage's absolute fill resolves against. */
.model-card__image {
  @apply relative w-full;
  aspect-ratio: 16 / 9;
}

/* ---------- selection tick ----------
   Kept in the DOM at every state so selecting a card cannot reflow it; scaled to
   nothing until it is earned. */
.model-card__check {
  @apply pointer-events-none absolute z-[2] flex items-center justify-center;
  @apply bg-primary rounded-full text-[11px] text-white opacity-0;
  @apply transition-[opacity,transform] duration-150 ease-in-out;
  top: 8px;
  right: 8px;
  width: 22px;
  height: 22px;
  transform: scale(0.6);
}

.model-card--selected .model-card__check {
  @apply opacity-100;
  transform: scale(1);
}

/* ---------- already-have markers ---------- */
.model-card__badges {
  @apply pointer-events-none absolute z-[2] flex flex-col items-start gap-1;
  top: 8px;
  left: 8px;
}

.model-card__badge {
  @apply rounded-control-bare text-[11px] leading-none whitespace-nowrap;
  @apply bg-gray-black/80 text-gray-lighter;
  padding: 4px 6px;
}

/* Gold, the token the app already uses for "notable about *your* copy" - and a
   dark glyph on it, because at 11px a tint this saturated is the only step that
   stays legible against the store image behind it. */
.model-card__badge--primary {
  background-color: rgb(212 175 55 / 0.9);
  color: #222;
}

/* ---------- meta ---------- */
.model-card__meta {
  @apply flex min-w-0 flex-col gap-1;
  padding: 8px 10px 10px;
}

.model-card__name {
  @apply text-lifted truncate text-[15px] leading-tight font-semibold;
}

.model-card__subtitle {
  @apply text-muted truncate text-[12px] leading-tight;
}

/* ---------- quantity ---------- */
.model-card__quantity {
  @apply absolute z-[2] flex items-center;
  @apply bg-gray-black/90 border-edge rounded-control-bare border;
  right: 8px;
  bottom: 8px;
}

.model-card__step {
  @apply text-text flex cursor-pointer items-center justify-center;
  @apply m-0 border-0 bg-transparent text-[11px];
  width: 24px;
  height: 24px;
}

.model-card__step:hover:not(:disabled) {
  @apply text-lifted;
}

.model-card__step:disabled {
  @apply cursor-default opacity-40;
}

.model-card__step:focus-visible {
  @apply outline-primary rounded-control-bare outline-2;
  outline-offset: -2px;
}

.model-card__count {
  @apply text-lifted text-[13px] leading-none font-semibold;
  min-width: 18px;
  text-align: center;
  font-variant-numeric: tabular-nums;
}

@media (prefers-reduced-motion: reduce) {
  .model-card,
  .model-card__check {
    transition-duration: 1ms;
  }
}
</style>
