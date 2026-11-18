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
  // Framed with a light ring: what a reader travels to.
  framed: boolean;
}

// Monochrome, as the rest of the app: a place reads by its glyph and its
// size, and colour is kept for selection and for the jump points that lead
// out of the system.
const MAJOR: StarmapMarker = { size: 22, color: "#eeeeee", framed: true };
const PLACE: StarmapMarker = { size: 15, color: "#b9bfc5", framed: false };

export const MARKERS: Partial<Record<LocationKindEnum, StarmapMarker>> = {
  [LocationKindEnum.STATION]: MAJOR,
  [LocationKindEnum.CITY]: MAJOR,
  [LocationKindEnum.SPACEPORT]: MAJOR,
  [LocationKindEnum.JUMP_POINT]: { size: 22, color: "#c39bd3", framed: true },
  [LocationKindEnum.OUTPOST]: PLACE,
  [LocationKindEnum.CLINIC]: PLACE,
  [LocationKindEnum.DISTRICT]: PLACE,
  [LocationKindEnum.POINT_OF_INTEREST]: PLACE,
  [LocationKindEnum.ASTEROID]: { size: 12, color: "#959595", framed: false },
  [LocationKindEnum.ANOMALY]: { size: 13, color: "#c39bd3", framed: false },
  [LocationKindEnum.NAV_POINT]: { size: 11, color: "#959595", framed: false },
};

const OTHER: StarmapMarker = { size: 12, color: "#959595", framed: false };

export const markerOf = (kind: LocationKindEnum) => MARKERS[kind] ?? OTHER;

// Drawn larger than shown, so the glyph stays sharp on a dense screen.
const PIXELS = 96;

// The glyph in its colour on a dark disc, so it reads over a bright surface
// as well as over space.
const svgOf = (kind: LocationKindEnum, color: string, framed: boolean) => {
  const glyph = GLYPHS[kind] ?? GLYPHS[LocationKindEnum.OTHER];
  const scoped = (markup?: string) => markup?.replaceAll("{id}", "g") ?? "";
  const width = glyph.width ?? 512;

  return (
    `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-96 -96 ${width + 192} 704" color="${color}">` +
    `<circle cx="${width / 2}" cy="256" r="330" fill="#121417" fill-opacity="0.85"${
      framed ? ` stroke="#eeeeee" stroke-opacity="0.55" stroke-width="24"` : ""
    }/>` +
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
  const { color, framed } = markerOf(kind);
  const key = `${kind}:${color}:${framed}`;
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
  image.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svgOf(kind, color, framed))}`;

  return texture;
};

// The textures outlive any one scene: there are a dozen of them at most.
export const disposeMarkers = () => {
  for (const texture of cache.values()) texture.dispose();
  cache.clear();
};
