<script lang="ts">
export default {
  name: "FleetSquadronEmblem",
};
</script>

<script lang="ts" setup>
import type { FleetSquadron, FleetSquadronRef } from "@/services/fyApi";

type Props = {
  squadron: FleetSquadron | FleetSquadronRef;
  size?: number;
};

const props = withDefaults(defineProps<Props>(), {
  size: 44,
});

const mark = computed(() => {
  const squadron = props.squadron as {
    icon?: { smallUrl?: string | null } | null;
    logo?: { smallUrl?: string | null } | null;
  };

  return squadron.icon?.smallUrl || squadron.logo?.smallUrl || undefined;
});

// Up to two words, so "Combat Wing" reads CW and "Alpha" reads A. Taken from
// the name rather than the slug: the slug is lowercased and a squadron called
// "3rd Wing" would give "3W" either way, but an accented name survives here.
const initials = computed(() =>
  props.squadron.name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => [...word][0]?.toUpperCase() ?? "")
    .join(""),
);

const colour = computed(() => props.squadron.color || undefined);

/*
 * Black or white, whichever the chosen colour can carry. A squadron's colour is
 * picked from the full wheel, so a fixed foreground is unreadable on roughly
 * half of it -- #d4af37 with white on it fails every contrast bar.
 *
 * sRGB relative luminance, thresholded at the value where black and white
 * contrast equally (0.179 by WCAG's formula, rounded here to the same place
 * the ratio flips).
 */
const foreground = computed(() => {
  const hex = colour.value;

  if (!hex) return undefined;

  const expanded =
    hex.length === 4
      ? `#${hex[1]}${hex[1]}${hex[2]}${hex[2]}${hex[3]}${hex[3]}`
      : hex;

  const channel = (offset: number) => {
    const value = parseInt(expanded.slice(offset, offset + 2), 16) / 255;

    return value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
  };

  const luminance =
    0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);

  return luminance > 0.179 ? "#000" : "#fff";
});

const box = computed(() => ({
  width: `${props.size}px`,
  height: `${props.size}px`,
}));

/*
 * A logo is never given a coloured tile behind it.
 *
 * Most emblems are uploaded as transparent PNGs, and a tile turns one into a
 * sticker on a coloured square. The tile was only ever decoration there --
 * `object-fit: contain` means an opaque logo covers it anyway, bar the
 * letterbox bars -- and the squadron's colour is already carried at full height
 * by the card's rail, so nothing is lost by dropping it.
 *
 * Detecting transparency per blob is possible (`AttachmentTrimmer` already asks
 * vips `has_alpha?`) but it would need the answer stored on the blob and
 * carried through the payload, to decide something that does not need deciding.
 */
const logoStyle = computed(() => box.value);

// The initials are the one case where the colour *is* the emblem, so here the
// tile earns its place -- and the text has to be readable on it.
const tileStyle = computed(() => ({
  ...box.value,
  fontSize: `${Math.round(props.size * 0.36)}px`,
  ...(colour.value
    ? { backgroundColor: colour.value, color: foreground.value }
    : {}),
}));
</script>

<template>
  <img
    v-if="mark"
    :src="mark"
    :alt="squadron.name"
    class="squadron-emblem squadron-emblem--logo"
    :style="logoStyle"
  />
  <span
    v-else
    class="squadron-emblem"
    :class="{ 'squadron-emblem--plain': !colour }"
    :style="tileStyle"
    aria-hidden="true"
  >
    {{ initials }}
  </span>
</template>

<style lang="scss" scoped>
.squadron-emblem {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border-radius: var(--radius-control, 8px);
  font-family: "Orbitron", tahoma, sans-serif;
  letter-spacing: 0.06em;
  line-height: 1;
  user-select: none;
}

// A squadron nobody gave a colour gets the quiet grey a glyph takes, on the
// panel's own surface rather than a filled disc -- an unfilled emblem should
// not out-shout one somebody chose a colour for.
.squadron-emblem--plain {
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  color: var(--color-muted, #7a8288);
}

.squadron-emblem--logo {
  object-fit: contain;
  background: none;
}
</style>
