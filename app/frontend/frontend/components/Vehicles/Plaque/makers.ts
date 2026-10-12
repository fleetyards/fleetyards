import anvl from "@/images/plaque/emblems/anvl.png";
import rsi from "@/images/plaque/emblems/rsi.png";
import aegs from "@/images/plaque/emblems/aegs.png";
import drak from "@/images/plaque/emblems/drak.png";
import misc from "@/images/plaque/emblems/misc.png";
import orig from "@/images/plaque/emblems/orig.png";
import crus from "@/images/plaque/emblems/crus.png";
import argo from "@/images/plaque/emblems/argo.png";
import tmbl from "@/images/plaque/emblems/tmbl.png";
import mrai from "@/images/plaque/emblems/mrai.png";
import grin from "@/images/plaque/emblems/grin.png";
import cnou from "@/images/plaque/emblems/cnou.png";
import espr from "@/images/plaque/emblems/espr.png";
import krig from "@/images/plaque/emblems/krig.png";
import xnaa from "@/images/plaque/emblems/xnaa.png";
import gama from "@/images/plaque/emblems/gama.png";
import banu from "@/images/plaque/emblems/banu.png";
import grey from "@/images/plaque/emblems/grey.png";
import vncl from "@/images/plaque/emblems/vncl.png";

export type PlaqueMaker = {
  // The `vehicle-plaque--maker-<theme>` style in `styles/makers.scss`.
  theme: string;
  emblem: string;
  // A single-colour emblem is drawn through a mask in the style's colour; a
  // multi-colour logo is shown as it is.
  tint: boolean;
  // The emblem's own aspect ratio, which its size is worked out from.
  aspect: number;
  // Hand-tuned for marks whose ink fills little of their box (a tagline, a thin
  // outline) or a lot (a solid block wordmark).
  optical?: number;
};

// Keyed by manufacturer code. The emblems ship with the frontend rather than
// coming from the uploads: they are trimmed for the plaque, and the CDN serves
// them with the CORS header the masks and the PNG download need.
export const PLAQUE_MAKERS: Record<string, PlaqueMaker> = {
  ANVL: { theme: "anvil", emblem: anvl, tint: true, aspect: 136 / 216 },
  RSI: {
    theme: "rsi",
    emblem: rsi,
    tint: true,
    aspect: 198 / 88,
    optical: 0.85,
  },
  AEGS: { theme: "aegis", emblem: aegs, tint: true, aspect: 195 / 146 },
  DRAK: {
    theme: "drake",
    emblem: drak,
    tint: true,
    aspect: 600 / 227,
    optical: 0.95,
  },
  MISC: {
    theme: "misc",
    emblem: misc,
    tint: false,
    aspect: 600 / 228,
    optical: 1.4,
  },
  ORIG: { theme: "origin", emblem: orig, tint: true, aspect: 210 / 118 },
  CRUS: { theme: "crusader", emblem: crus, tint: true, aspect: 126 / 212 },
  ARGO: { theme: "argo", emblem: argo, tint: true, aspect: 134 / 110 },
  TMBL: { theme: "tumbril", emblem: tmbl, tint: true, aspect: 182 / 192 },
  MRAI: { theme: "mirai", emblem: mrai, tint: true, aspect: 369 / 500 },
  GRIN: { theme: "greycat", emblem: grin, tint: true, aspect: 1, optical: 0.9 },
  CNOU: { theme: "co", emblem: cnou, tint: true, aspect: 206 / 140 },
  ESPR: { theme: "esperia", emblem: espr, tint: true, aspect: 148 / 172 },
  KRIG: {
    theme: "kruger",
    emblem: krig,
    tint: false,
    aspect: 262 / 201,
    optical: 1.3,
  },
  XNAA: { theme: "aopoa", emblem: xnaa, tint: true, aspect: 96 / 216 },
  GAMA: { theme: "gatac", emblem: gama, tint: true, aspect: 198 / 160 },
  BANU: { theme: "banu", emblem: banu, tint: true, aspect: 196 / 178 },
  GREY: { theme: "greys", emblem: grey, tint: true, aspect: 1, optical: 1.15 },
  // The game files give Vanduul Esperia's icon, so its plaque uses the logo.
  VNCL: {
    theme: "vanduul",
    emblem: vncl,
    tint: false,
    aspect: 96 / 49,
    optical: 1.15,
  },
};

const BASE_HEIGHT = 11.5;
const MAX_WIDTH = 38;
const MAX_HEIGHT = 15;

// Sized optically: a square emblem gets the base height and a wider one gives
// up height by its aspect ratio to the 0.35 -- between equal height (wordmarks
// dominate) and equal area (wordmarks shrink to nothing). In cqw.
export const emblemSize = (maker: PlaqueMaker) => {
  let height = BASE_HEIGHT * maker.aspect ** -0.35 * (maker.optical ?? 1);
  let width = height * maker.aspect;

  if (width > MAX_WIDTH) {
    width = MAX_WIDTH;
    height = width / maker.aspect;
  }
  if (height > MAX_HEIGHT) {
    height = MAX_HEIGHT;
    width = height * maker.aspect;
  }

  return { width: `${width.toFixed(2)}cqw`, height: `${height.toFixed(2)}cqw` };
};
