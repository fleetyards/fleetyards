import { CanvasTexture, SRGBColorSpace, type Texture } from "three";
import { LocationKindEnum } from "@/services/fyApi";
import { GLYPHS } from "@/frontend/components/Locations/KindIcon/glyphs";

/**
 * Places on the map are drawn with the glyphs the location pages give their
 * kinds, so a station reads as a station and an outpost as an outpost, and
 * what a reader travels to stands out from what is merely there.
 */
export interface StarmapMarker {
  // Across, in pixels, whatever the distance.
  size: number;
  color: string;
}

const MAJOR: StarmapMarker = { size: 24, color: "#7fd0ff" };

export const MARKERS: Partial<Record<LocationKindEnum, StarmapMarker>> = {
  [LocationKindEnum.STATION]: MAJOR,
  [LocationKindEnum.CITY]: { size: 24, color: "#ffd27a" },
  [LocationKindEnum.SPACEPORT]: { size: 22, color: "#ffd27a" },
  [LocationKindEnum.JUMP_POINT]: { size: 24, color: "#c3a6ff" },
  [LocationKindEnum.OUTPOST]: { size: 14, color: "#9fb3c8" },
  [LocationKindEnum.CLINIC]: { size: 14, color: "#ff9d94" },
  [LocationKindEnum.DISTRICT]: { size: 13, color: "#ffd27a" },
  [LocationKindEnum.POINT_OF_INTEREST]: { size: 13, color: "#9fb3c8" },
  [LocationKindEnum.ASTEROID]: { size: 11, color: "#b0a196" },
  [LocationKindEnum.ANOMALY]: { size: 12, color: "#c3a6ff" },
  [LocationKindEnum.NAV_POINT]: { size: 10, color: "#90a4ae" },
};

const OTHER: StarmapMarker = { size: 12, color: "#90a4ae" };

export const markerOf = (kind: LocationKindEnum) => MARKERS[kind] ?? OTHER;

// Drawn larger than shown, so the glyph stays sharp on a dense screen.
const PIXELS = 96;

// The glyph in its colour on a dark disc, so it reads over a bright surface
// as well as over space.
const svgOf = (kind: LocationKindEnum, color: string) => {
  const glyph = GLYPHS[kind] ?? GLYPHS[LocationKindEnum.OTHER];
  const scoped = (markup?: string) => markup?.replaceAll("{id}", "g") ?? "";
  const width = glyph.width ?? 512;

  return (
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-96 -96 ${width + 192} 704" color="${color}">` +
    `<circle cx="${width / 2}" cy="256" r="340" fill="#050a12" fill-opacity="0.72"/>` +
    `<defs>${scoped(glyph.defs)}</defs>` +
    `<g fill="${color}" opacity="0.45">${scoped(glyph.secondary)}</g>` +
    `<g fill="${color}">${scoped(glyph.primary)}</g>` +
    "</svg>"
  );
};

const cache = new Map<string, Texture>();

/**
 * A kind's marker as a texture. Drawn once per kind and colour, and filled in
 * as soon as the browser has read the SVG; until then it is transparent.
 */
export const markerTexture = (kind: LocationKindEnum): Texture => {
  const { color } = markerOf(kind);
  const key = `${kind}:${color}`;
  const known = cache.get(key);
  if (known) return known;

  const canvas = document.createElement("canvas");
  canvas.width = PIXELS;
  canvas.height = PIXELS;

  const texture = new CanvasTexture(canvas);
  texture.colorSpace = SRGBColorSpace;
  cache.set(key, texture);

  const image = new Image();
  image.onload = () => {
    canvas.getContext("2d")?.drawImage(image, 0, 0, PIXELS, PIXELS);
    texture.needsUpdate = true;
  };
  image.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svgOf(kind, color))}`;

  return texture;
};

// The textures outlive any one scene: there are a dozen of them at most.
export const disposeMarkers = () => {
  for (const texture of cache.values()) texture.dispose();
  cache.clear();
};
