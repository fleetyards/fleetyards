import { LocationKindEnum } from "@/services/fyApi";

// One glyph per kind on Font Awesome's 512 grid, in its duotone shape: a
// faded secondary layer under a full primary one. `{id}` is replaced per
// rendered icon, so two icons on a page never share a mask.
export type Glyph = {
  defs?: string;
  secondary: string;
  primary: string;
};

const SECONDARY_STROKE = 'stroke="var(--fa-secondary-color, currentColor)"';
const PRIMARY_STROKE = 'stroke="var(--fa-primary-color, currentColor)"';

const mask = (id: string, content: string) =>
  `<mask id="{id}-${id}" maskUnits="userSpaceOnUse" x="-64" y="-64" width="640" height="640"><rect x="-64" y="-64" width="640" height="640" fill="#fff"/>${content}</mask>`;

export const GLYPHS: Record<LocationKindEnum, Glyph> = {
  [LocationKindEnum.SYSTEM]: {
    secondary: `<g fill="none" ${SECONDARY_STROKE} stroke-width="22"><circle cx="256" cy="256" r="124"/><circle cx="256" cy="256" r="216"/></g>`,
    primary:
      '<circle cx="256" cy="256" r="60"/><circle cx="408" cy="104" r="44"/><circle cx="168" cy="345" r="30"/>',
  },
  // A disc and its glow, in two steps.
  [LocationKindEnum.STAR]: {
    secondary:
      '<circle cx="256" cy="256" r="236" fill-opacity="0.5"/><circle cx="256" cy="256" r="196"/>',
    primary: '<circle cx="256" cy="256" r="150"/>',
  },
  // The ring passes behind the sphere at the top and in front of it at the
  // bottom, with a gap cut into the sphere where it crosses.
  [LocationKindEnum.PLANET]: {
    defs:
      mask(
        "back",
        '<path d="M110 256 A146 146 0 0 1 402 256 Z" fill="#000"/>',
      ) +
      mask(
        "gap",
        '<g transform="rotate(-22 256 256)"><path d="M20 256 A236 76 0 0 0 492 256" fill="none" stroke="#000" stroke-width="76"/></g>',
      ),
    secondary: `<g transform="rotate(-22 256 256)" mask="url(#{id}-back)"><ellipse cx="256" cy="256" rx="236" ry="76" fill="none" ${SECONDARY_STROKE} stroke-width="34"/></g>`,
    primary: '<circle cx="256" cy="256" r="146" mask="url(#{id}-gap)"/>',
  },
  [LocationKindEnum.MOON]: {
    defs: mask("shade", '<circle cx="336" cy="196" r="172" fill="#000"/>'),
    secondary: '<circle cx="256" cy="256" r="200"/>',
    primary: '<circle cx="256" cy="256" r="200" mask="url(#{id}-shade)"/>',
  },
  [LocationKindEnum.CITY]: {
    defs: mask(
      "windows",
      `<g fill="#000">${[232, 290, 348].map((y) => `<rect x="132" y="${y}" width="24" height="28" rx="4"/>`).join("")}${[196, 254, 312, 370].map((y) => `<rect x="292" y="${y}" width="24" height="28" rx="4"/>`).join("")}</g>`,
    ),
    secondary:
      '<rect x="196" y="120" width="72" height="320" rx="10"/><rect x="360" y="232" width="96" height="208" rx="10"/><rect x="216" y="64" width="12" height="60" rx="6"/>',
    primary:
      '<g mask="url(#{id}-windows)"><rect x="104" y="200" width="88" height="240" rx="10"/><rect x="264" y="164" width="88" height="276" rx="10"/></g><rect x="40" y="432" width="432" height="40" rx="12"/>',
  },
  [LocationKindEnum.STATION]: {
    secondary:
      '<rect x="24" y="136" width="120" height="104" rx="10"/><rect x="24" y="272" width="120" height="104" rx="10"/><rect x="368" y="136" width="120" height="104" rx="10"/><rect x="368" y="272" width="120" height="104" rx="10"/>',
    primary:
      '<rect x="132" y="242" width="248" height="28" rx="10"/><rect x="242" y="56" width="28" height="400" rx="12"/><circle cx="256" cy="256" r="72"/><circle cx="256" cy="56" r="26"/>',
  },
  [LocationKindEnum.OUTPOST]: {
    secondary: '<path d="M56 416 A152 152 0 0 1 360 416 Z"/>',
    primary:
      '<rect x="32" y="408" width="448" height="40" rx="12"/><rect x="170" y="336" width="76" height="80" rx="14"/><rect x="404" y="108" width="28" height="308" rx="10"/><path d="M432 108 L496 140 L432 172 Z"/>',
  },
  // A clinic: a cross on a rounded panel.
  [LocationKindEnum.CLINIC]: {
    secondary: '<rect x="40" y="40" width="432" height="432" rx="72"/>',
    primary:
      '<rect x="216" y="104" width="80" height="304" rx="16"/><rect x="104" y="216" width="304" height="80" rx="16"/>',
  },
  // A district: a few buildings on the platform they stand on.
  [LocationKindEnum.DISTRICT]: {
    secondary: '<path d="M40 340 L472 340 L404 452 L108 452 Z"/>',
    primary:
      '<rect x="96" y="200" width="88" height="128" rx="10"/><rect x="212" y="104" width="88" height="224" rx="10"/><rect x="328" y="168" width="88" height="160" rx="10"/><rect x="40" y="320" width="432" height="36" rx="12"/>',
  },
  [LocationKindEnum.ASTEROID]: {
    defs: mask(
      "craters",
      '<circle cx="214" cy="226" r="40" fill="#000"/><circle cx="300" cy="320" r="28" fill="#000"/><circle cx="318" cy="208" r="18" fill="#000"/>',
    ),
    secondary:
      '<path d="M402 70 L452 84 L466 128 L436 156 L392 142 L380 98 Z"/><path d="M70 392 L108 380 L132 410 L118 450 L78 456 L56 424 Z"/>',
    primary:
      '<path mask="url(#{id}-craters)" d="M168 112 L284 96 L372 150 L410 252 L380 360 L280 420 L170 404 L104 324 L96 212 Z"/>',
  },
  [LocationKindEnum.ANOMALY]: {
    secondary: `<path d="M408 48 Q416 88 456 96 Q416 104 408 144 Q400 104 360 96 Q400 88 408 48 Z"/><path d="M104 368 Q110 398 140 404 Q110 410 104 440 Q98 410 68 404 Q98 398 104 368 Z"/><circle cx="256" cy="256" r="196" fill="none" ${SECONDARY_STROKE} stroke-width="20" stroke-dasharray="58 40"/>`,
    primary:
      '<path d="M256 88 Q276 236 424 256 Q276 276 256 424 Q236 276 88 256 Q236 236 256 88 Z"/>',
  },
  [LocationKindEnum.JUMP_POINT]: {
    secondary: `<g fill="none" ${SECONDARY_STROKE} stroke-width="34" stroke-linecap="round"><path d="M256 40 A216 216 0 0 1 472 256"/><path d="M256 472 A216 216 0 0 1 40 256"/><path d="M118 118 A196 196 0 0 1 200 66"/><path d="M394 394 A196 196 0 0 1 312 446"/></g>`,
    primary: `<path d="M256 136 A120 120 0 1 1 136 256" fill="none" ${PRIMARY_STROKE} stroke-width="40" stroke-linecap="round"/><circle cx="256" cy="256" r="48"/>`,
  },
  [LocationKindEnum.POINT_OF_INTEREST]: {
    defs: mask("hole", '<circle cx="256" cy="196" r="58" fill="#000"/>'),
    secondary: '<ellipse cx="256" cy="450" rx="150" ry="38"/>',
    primary:
      '<path mask="url(#{id}-hole)" d="M256 24 C356 24 432 98 432 196 C432 300 320 396 256 448 C192 396 80 300 80 196 C80 98 156 24 256 24 Z"/>',
  },
  [LocationKindEnum.NAV_POINT]: {
    secondary: `<circle cx="256" cy="256" r="164" fill="none" ${SECONDARY_STROKE} stroke-width="40"/>`,
    primary:
      '<rect x="238" y="16" width="36" height="128" rx="14"/><rect x="238" y="368" width="36" height="128" rx="14"/><rect x="16" y="238" width="128" height="36" rx="14"/><rect x="368" y="238" width="128" height="36" rx="14"/><circle cx="256" cy="256" r="48"/>',
  },
  [LocationKindEnum.OTHER]: {
    secondary: '<circle cx="256" cy="256" r="216"/>',
    primary: '<circle cx="256" cy="256" r="80"/>',
  },
};
