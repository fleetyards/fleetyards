import type { CSSProperties } from "vue";

type Appearance = {
  kind?: string;
  color?: string | null;
  bodyType?: string | null;
};

// Only a body is drawn as a sphere, from its colour. A picture, of a body or
// any other place, is the header on its page.
const GLOBE_KINDS = ["planet", "moon"];

export const isGlobeKind = (kind?: string) =>
  !!kind && GLOBE_KINDS.includes(kind);

// The colour a body's circle is drawn in, for the globe component, or nothing
// -- the circle keeps the plain fill its stylesheet gives it. A filled circle
// drops its grey outline through the variable, so a lit circle's own border,
// set by class, still wins.
export const globeStyle = (
  appearance?: Appearance | null,
): CSSProperties | undefined => {
  if (!isGlobeKind(appearance?.kind) || !appearance?.color) return undefined;

  return {
    "--globe-color": appearance.color,
    "--globe-border": "transparent",
  };
};

// A star is drawn by the sun mixin, which only needs its colour.
export const sunStyle = (
  appearance?: Appearance | null,
): CSSProperties | undefined =>
  appearance?.kind === "star" && appearance.color
    ? { "--sun-color": appearance.color }
    : undefined;
