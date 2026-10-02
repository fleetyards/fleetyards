import type { CSSProperties } from "vue";

type Appearance = {
  kind?: string;
  color?: string | null;
};

// Only a body is drawn as a sphere, from its colour. A picture, of a body or
// any other place, is the header on its page.
const GLOBE_KINDS = ["planet", "moon"];

export const isGlobeKind = (kind?: string) =>
  !!kind && GLOBE_KINDS.includes(kind);

// Sized to the border box and not tiled: sized to the padding box, the next
// tile's highlight shows through the 1px border as a bright sliver along the
// bottom and right edges. The grey outline goes too, through the variable, so
// a lit circle's own border, set by class, still wins.
const FILL: CSSProperties = {
  backgroundOrigin: "border-box",
  backgroundRepeat: "no-repeat",
  "--globe-border": "transparent",
};

// How a body's circle is filled: its colour shaded like a lit sphere, or
// nothing -- the circle keeps the plain fill its stylesheet gives it.
export const globeStyle = (
  appearance?: Appearance | null,
): CSSProperties | undefined => {
  if (!isGlobeKind(appearance?.kind)) return undefined;

  const color = appearance?.color;

  if (!color) return undefined;

  return {
    backgroundImage: `radial-gradient(circle at 32% 28%, color-mix(in srgb, ${color} 55%, #fff) 0%, ${color} 38%, color-mix(in srgb, ${color} 40%, #000) 78%, color-mix(in srgb, ${color} 15%, #000) 100%)`,
    ...FILL,
  };
};

// A star is drawn by the sun mixin, which only needs its colour.
export const sunStyle = (
  appearance?: Appearance | null,
): CSSProperties | undefined =>
  appearance?.kind === "star" && appearance.color
    ? { "--sun-color": appearance.color }
    : undefined;
