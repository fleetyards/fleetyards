import { HardpointCategoryEnum } from "@/services/fyApi";
import {
  type Glyph,
  PRIMARY_STROKE,
  SECONDARY_STROKE,
  mask,
} from "@/shared/components/DuotoneGlyph/glyph";

// The hardpoint icons people already know, redrawn as duotone glyphs on the
// 512 grid: the part that names the category is the primary layer, its frame
// or housing the secondary one. Corners are rounded the same way throughout,
// and the secondary layer is cut back around the primary, so the two never
// touch.
const GAP = 20;

const line = (stroke: string, width: number, cap = "round") =>
  `fill="none" ${stroke} stroke-width="${width}" stroke-linecap="${cap}" stroke-linejoin="round"`;
const PRIMARY_LINE = line(PRIMARY_STROKE, 44);
const SECONDARY_LINE = line(SECONDARY_STROKE, 44);

// A polygon with its corners rounded by a stroke of its own colour.
const soft = (d: string, stroke: string, radius = 12) =>
  `<path d="${d}" ${stroke} stroke-width="${radius * 2}" stroke-linejoin="round"/>`;
const primary = (d: string, radius?: number) => soft(d, PRIMARY_STROKE, radius);
const secondary = (d: string, radius?: number) =>
  soft(d, SECONDARY_STROKE, radius);

// The primary layer drawn black and widened by the gap, as the mask that cuts
// it out of the secondary layer. The colour variable is pinned to black too,
// since a page may set it.
const knockout = (glyph: Glyph): Glyph => ({
  ...glyph,
  defs:
    (glyph.defs ?? "") +
    mask(
      "knockout",
      `<g fill="#000" stroke="#000" stroke-width="${GAP * 2}" stroke-linejoin="round" color="#000" style="--fa-primary-color: #000">${glyph.primary}</g>`,
    ),
  secondary: `<g mask="url(#{id}-knockout)">${glyph.secondary}</g>`,
});

const point = (cx: number, cy: number, r: number, deg: number) => {
  const a = (deg * Math.PI) / 180;
  return [cx + r * Math.cos(a), cy + r * Math.sin(a)] as const;
};
const at = (cx: number, cy: number, r: number, deg: number) =>
  point(cx, cy, r, deg)
    .map((v) => v.toFixed(1))
    .join(" ");

const star = (points: number, outer: number, inner: number) =>
  `M${Array.from({ length: points * 2 }, (_, i) =>
    at(256, 256, i % 2 ? inner : outer, (180 * i) / points - 90),
  ).join(" L")} Z`;

const hexagon = (cx: number, cy: number, r: number) =>
  `M${Array.from({ length: 6 }, (_, i) => at(cx, cy, r, 60 * i - 90)).join(" L")} Z`;

const rotations = (count: number, markup: string, offset = 0) =>
  Array.from(
    { length: count },
    (_, i) =>
      `<g transform="rotate(${offset + (360 / count) * i} 256 256)">${markup}</g>`,
  ).join("");

const SHIELD =
  "M256 32 L432 96 Q448 102 448 120 L448 240 C448 360 368 440 256 480 C144 440 64 360 64 240 L64 120 Q64 102 80 96 Z";
const SHIELD_LEFT =
  "M256 32 L80 96 Q64 102 64 120 L64 240 C64 360 144 440 256 480 Z";
const SHIELD_RIGHT =
  "M256 32 L432 96 Q448 102 448 120 L448 240 C448 360 368 440 256 480 Z";

// The brackets a power plant's bolt sits in.
const BRACKETS =
  "M192 40 L120 40 Q48 40 48 112 L48 400 Q48 472 120 472 L192 472 L192 408 L144 408 Q112 408 112 376 L112 136 Q112 104 144 104 L192 104 Z M320 40 L392 40 Q464 40 464 112 L464 400 Q464 472 392 472 L320 472 L320 408 L368 408 Q400 408 400 376 L400 136 Q400 104 368 104 L320 104 Z";
const BOLT = "M292 72 L168 280 L248 280 L220 440 L344 224 L264 224 Z";

const DIAMOND =
  "M226 46 Q256 16 286 46 L466 226 Q496 256 466 286 L286 466 Q256 496 226 466 L46 286 Q16 256 46 226 Z";
const CROSS =
  '<rect x="232" y="120" width="48" height="272" rx="20"/><rect x="120" y="232" width="272" height="48" rx="20"/><rect x="200" y="200" width="112" height="112" rx="20"/>';

// A slash from the top left to the bottom right, and the gap it cuts.
const SLASH = "M72 72 L440 440";
const SLASH_GAP = mask(
  "slash",
  `<path d="${SLASH}" stroke="#000" stroke-width="${36 + GAP * 2}"/>`,
);
const slashed = (markup: string) =>
  `<g mask="url(#{id}-slash)">${markup}</g><path d="${SLASH}" ${line(PRIMARY_STROKE, 36)}/>`;

const JERRYCAN =
  "M200 48 L400 48 Q448 48 448 96 L448 432 Q448 480 400 480 L112 480 Q64 480 64 432 L64 184 Z";
const JERRYCAN_SPOUT =
  '<rect x="40" y="72" width="128" height="52" rx="18" transform="rotate(-45 104 98)"/>';
const JERRYCAN_HANDLE = mask(
  "handle",
  '<rect x="264" y="88" width="128" height="44" rx="22" fill="#000"/>',
);
const DROP =
  "M256 200 C256 200 168 296 168 352 A88 88 0 0 0 344 352 C344 296 256 200 256 200 Z";

// The intake's housing, open to the left.
const INTAKE =
  "M232 104 L360 104 Q376 104 386 118 L470 238 Q482 256 470 274 L386 394 Q376 408 360 408 L232 408 L232 336 L320 336 L376 256 L320 176 L232 176 Z";

// A thruster: the nozzle's curve behind, the way it pushes in front.
const NOZZLE =
  "M184 56 Q40 120 40 256 Q40 392 184 456 L216 392 Q112 344 112 256 Q112 168 216 120 Z";
const CHEVRONS = `<path d="M224 128 L344 256 L224 384 M336 128 L456 256 L336 384" ${line(PRIMARY_STROKE, 64)}/>`;
const thruster = (transform = "") => ({
  secondary: `<g transform="${transform}">${secondary(NOZZLE, 8)}</g>`,
  primary: `<g transform="${transform}">${CHEVRONS}</g>`,
});
const smallThruster = (cx: number, cy: number, mirrored = false) =>
  `<g transform="translate(${cx - 112} ${cy - 112}) scale(0.44)${mirrored ? " translate(512 0) scale(-1 1)" : ""}">${primary(NOZZLE, 8)}${CHEVRONS}</g>`;

// A round pointing up: its tip, and the casing behind it.
const round = (cx: number, top: number) => ({
  tip: `<path d="M${cx - 40} ${top + 120} Q${cx - 40} ${top + 40} ${cx} ${top} Q${cx + 40} ${top + 40} ${cx + 40} ${top + 120} Z"/>`,
  casing: `<rect x="${cx - 44}" y="${top + 144}" width="88" height="160" rx="16"/>`,
});
const ROUNDS = [round(144, 72), round(256, 32), round(368, 72)];

// A missile pointing up: the body and nose, then its fins and nozzle.
const MISSILE_BODY =
  "M256 24 Q312 80 312 160 L312 360 L200 360 L200 160 Q200 80 256 24 Z";
const MISSILE_FINS =
  "M184 240 L112 344 L112 416 L184 384 Z M328 240 L400 344 L400 416 L328 384 Z";
const MISSILE_NOZZLE = '<rect x="216" y="384" width="80" height="80" rx="16"/>';

const RECYCLE = rotations(
  3,
  `<path d="M184 252 L240 156" ${PRIMARY_LINE}/><path d="M212 156 L244 152 L260 180" ${line(PRIMARY_STROKE, 32)}/>`,
);

const CRANE =
  "M332.7 90.7 L458.7 90.7 L480 69.6 L32 69.6 L53.1 90.7 L182.8 90.7 L182.8 110.9 L197.9 126.3 L88.6 126.3 L109.4 147 L210.4 147 L210.4 246.5 L196.1 260.7 L196.1 345.2 L210.4 359.8 L232.5 359.8 C233.7 384.3 236.4 397.7 255.4 415.1 A35.1 35.1 0 0 1 269.8 439.6 A28 28 0 0 1 213.9 440.4 A5.3 5.3 0 0 0 208.5 435.4 A6.1 6.1 0 0 0 202.9 441 S202.9 442.3 202.9 442.4 A53 53 0 1 0 288.7 401.4 A51.4 51.4 0 0 1 272.5 360.2 L302.3 360.2 L316.5 345.6 L316.5 306.2 L307.1 296.5 L307.1 147 L401.8 147 L423.3 125.9 L317 125.9 L332.7 110.2 Z M284.9 274.5 L257.3 246.5 L232.8 246.5 L232.8 147 L284.9 147 Z";

export const HARDPOINT_GLYPHS: Record<HardpointCategoryEnum, Glyph> = {
  // A scope: its crosshair and range ring, and the sweep that finds a contact.
  [HardpointCategoryEnum.RADAR]: knockout({
    defs: mask(
      "scope",
      `<g fill="none" stroke="#000" stroke-width="${GAP * 1.25}"><path d="M256 0 L256 512 M0 256 L512 256"/><circle cx="256" cy="256" r="144"/></g>`,
    ),
    secondary: '<circle cx="256" cy="256" r="232" mask="url(#{id}-scope)"/>',
    primary:
      '<path d="M256 256 L464 256 A208 208 0 0 1 403 403 Z"/><circle cx="256" cy="256" r="40"/><circle cx="160" cy="160" r="32"/>',
  }),
  // A chip: its die inside the octagon, and the pins on every side.
  [HardpointCategoryEnum.COMPUTERS]: knockout({
    defs: mask(
      "die",
      primary(
        "M200 160 L312 160 L352 200 L352 312 L312 352 L200 352 L160 312 L160 200 Z",
        8,
      ).replace(PRIMARY_STROKE, 'fill="#000" stroke="#000"'),
    ),
    secondary: rotations(
      4,
      [176, 256, 336]
        .map(
          (x) => `<rect x="${x - 18}" y="16" width="36" height="80" rx="18"/>`,
        )
        .join(""),
    ),
    primary: `<g mask="url(#{id}-die)">${primary("M184 112 L328 112 L400 184 L400 328 L328 400 L184 400 L112 328 L112 184 Z", 20)}</g><rect x="208" y="208" width="96" height="96" rx="20"/>`,
  }),
  // A sweep fanning out from its emitter.
  [HardpointCategoryEnum.SCANNERS]: knockout({
    secondary: secondary("M256 448 L72 128 A368 368 0 0 1 440 128 Z", 16),
    primary: `<g ${PRIMARY_LINE}><path d="M164 290 A184 184 0 0 1 348 290"/><path d="M112 204 A288 288 0 0 1 400 204"/></g><circle cx="256" cy="440" r="52"/>`,
  }),
  [HardpointCategoryEnum.POWERPLANT]: knockout({
    secondary: `<path d="${BRACKETS}"/>`,
    primary: primary(BOLT, 16),
  }),
  // A fan in its round housing, its broad blades swept round the hub.
  [HardpointCategoryEnum.COOLER]: knockout({
    secondary: `<circle cx="256" cy="256" r="212" ${line(SECONDARY_STROKE, 56)}/>`,
    primary: `${rotations(
      5,
      primary("M236 208 Q196 128 248 64 Q312 60 352 96 Q296 132 284 200 Z", 6),
    )}<circle cx="256" cy="256" r="52"/>`,
  }),
  // A ring of cells around the one it guards.
  [HardpointCategoryEnum.SHIELDGENERATOR]: knockout({
    secondary: `<path d="${hexagon(256, 256, 72)}"/>`,
    primary: Array.from({ length: 6 }, (_, i) =>
      primary(hexagon(...point(256, 256, 160, 60 * i), 68), 12),
    ).join(""),
  }),
  [HardpointCategoryEnum.MODULE]: knockout({
    defs: mask(
      "sockets",
      '<circle cx="96" cy="296" r="56" fill="#000"/><circle cx="256" cy="456" r="56" fill="#000"/>',
    ),
    secondary:
      '<circle cx="256" cy="104" r="64"/><circle cx="424" cy="296" r="64"/>',
    primary:
      '<rect x="96" y="136" width="320" height="320" rx="40" mask="url(#{id}-sockets)"/>',
  }),
  // A bin with the recycling arrows on it.
  [HardpointCategoryEnum.SALVAGEFILLERSTATION]: knockout({
    secondary: `${secondary("M96 168 L416 168 L384 456 Q380 480 356 480 L156 480 Q132 480 128 456 Z", 12)}<rect x="56" y="96" width="400" height="52" rx="20"/><rect x="200" y="40" width="112" height="48" rx="16"/>`,
    primary: `<g transform="translate(256 324) scale(0.62) translate(-256 -256)">${RECYCLE}</g>`,
  }),
  [HardpointCategoryEnum.FUELTANKS]: knockout({
    defs: JERRYCAN_HANDLE,
    secondary: `<g mask="url(#{id}-handle)"><path d="${JERRYCAN}"/></g>${JERRYCAN_SPOUT}`,
    primary: `<path d="${DROP}"/>`,
  }),
  [HardpointCategoryEnum.FUEL_INTAKES]: knockout({
    secondary: secondary(INTAKE, 8),
    primary: `<rect x="24" y="228" width="200" height="56" rx="24"/>${primary("M184 152 L320 256 L184 360 Z", 16)}`,
  }),
  [HardpointCategoryEnum.QUANTUMDRIVE]: knockout({
    secondary: `<path d="${DIAMOND}"/>`,
    primary: CROSS,
  }),
  // The cross a jump drive folds space along, and the points it reaches.
  [HardpointCategoryEnum.JUMPDRIVE]: knockout({
    secondary: rotations(
      4,
      `<path d="M176 104 L256 32 L336 104" ${SECONDARY_LINE}/>`,
    ),
    primary: `<g transform="rotate(45 256 256)"><rect x="72" y="234" width="368" height="44" rx="22"/><rect x="234" y="72" width="44" height="368" rx="22"/></g><rect x="192" y="192" width="128" height="128" rx="24" transform="rotate(45 256 256)"/>`,
  }),
  // Two cans, carried rather than built in.
  [HardpointCategoryEnum.EXTERNAL_FUEL_TANKS]: knockout({
    defs:
      JERRYCAN_HANDLE +
      mask(
        "front",
        `<rect x="264" y="88" width="128" height="44" rx="22" fill="#000"/><path d="${DROP}" fill="#000"/>`,
      ),
    secondary: `<g transform="translate(8 8) scale(0.6)"><g mask="url(#{id}-handle)"><path d="${JERRYCAN}"/></g>${JERRYCAN_SPOUT}</g>`,
    primary: `<g transform="translate(184 184) scale(0.64)"><path d="${JERRYCAN}" mask="url(#{id}-front)"/>${JERRYCAN_SPOUT}</g>`,
  }),
  // The intake's arrow turned around: fuel handed out rather than taken in.
  [HardpointCategoryEnum.REFUEL_BOOM]: knockout({
    secondary: secondary(INTAKE, 8),
    primary: `<rect x="160" y="228" width="184" height="56" rx="24"/>${primary("M176 152 L40 256 L176 360 Z", 16)}`,
  }),
  [HardpointCategoryEnum.MAIN_THRUSTERS]: knockout(thruster()),
  [HardpointCategoryEnum.RETRO_THRUSTERS]: knockout(
    thruster("translate(512 0) scale(-1 1)"),
  ),
  [HardpointCategoryEnum.VTOL_THRUSTERS]: knockout(
    thruster("rotate(90 256 256)"),
  ),
  // Small thrusters pushing either way, and the turn they make.
  [HardpointCategoryEnum.MANEUVERING_THRUSTERS]: knockout({
    secondary: `<path d="M224 120 Q152 72 88 112" ${SECONDARY_LINE}/>${secondary("M48 128 L112 72 L120 156 Z", 8)}<path d="M288 120 Q360 72 424 112" ${SECONDARY_LINE}/>${secondary("M464 128 L400 72 L392 156 Z", 8)}`,
    primary: smallThruster(128, 352, true) + smallThruster(384, 352),
  }),
  // Three rounds: their tips, then their casings.
  [HardpointCategoryEnum.WEAPONS]: knockout({
    secondary: `<g transform="rotate(45 256 256)">${ROUNDS.map((r) => r.casing).join("")}</g>`,
    primary: `<g transform="rotate(45 256 256)">${ROUNDS.map((r) => r.tip).join("")}</g>`,
  }),
  // A ring and the point it holds: the mount rather than its weapon.
  [HardpointCategoryEnum.WEAPON_MOUNTS]: knockout({
    secondary: `<circle cx="256" cy="256" r="196" ${line(SECONDARY_STROKE, 64)}/>`,
    primary: '<circle cx="256" cy="256" r="96"/>',
  }),
  // Twin barrels on their tripod.
  [HardpointCategoryEnum.TURRET]: knockout({
    secondary: `<g ${SECONDARY_LINE}><path d="M184 352 L96 472"/><path d="M184 352 L272 472"/></g><circle cx="184" cy="344" r="48"/>`,
    primary:
      '<g transform="rotate(-24 184 232)"><rect x="56" y="168" width="208" height="136" rx="32"/><rect x="248" y="180" width="232" height="40" rx="20"/><rect x="248" y="252" width="232" height="40" rx="20"/></g>',
  }),
  // A missile and a smaller one beside it: a rack of them.
  [HardpointCategoryEnum.MISSILE_RACKS]: knockout({
    secondary: `<g transform="translate(24 24) scale(0.42) rotate(45 256 256)"><path d="${MISSILE_BODY}"/><path d="${MISSILE_FINS}"/>${MISSILE_NOZZLE}</g><g transform="translate(48 48) scale(0.9) rotate(45 256 256)">${secondary(MISSILE_FINS, 8)}${MISSILE_NOZZLE}</g>`,
    primary: `<g transform="translate(48 48) scale(0.9) rotate(45 256 256)"><path d="${MISSILE_BODY}"/></g>`,
  }),
  // A bomb stood on its fins.
  [HardpointCategoryEnum.BOMBCOMPARTMENTS]: knockout({
    secondary: `${secondary("M184 280 L112 400 L112 472 L184 432 Z M328 280 L400 400 L400 472 L328 432 Z", 8)}<rect x="216" y="400" width="80" height="80" rx="16"/>`,
    primary:
      '<path d="M256 32 C320 32 344 104 344 176 L344 304 Q344 384 256 384 Q168 384 168 304 L168 176 C168 104 192 32 256 32 Z"/>',
  }),
  [HardpointCategoryEnum.QUANTUMENFORCEMENTDEVICE]: knockout({
    defs: SLASH_GAP,
    secondary: `<g mask="url(#{id}-slash)"><path d="${DIAMOND}"/></g>`,
    primary: slashed(CROSS),
  }),
  [HardpointCategoryEnum.EMP]: knockout({
    defs: SLASH_GAP,
    secondary: `<g mask="url(#{id}-slash)"><path d="${BRACKETS}"/></g>`,
    primary: slashed(primary(BOLT, 16)),
  }),
  // An emitter with its beam, and the glow around it.
  [HardpointCategoryEnum.SALVAGEMUNCHING]: knockout({
    secondary: `<g ${SECONDARY_LINE}>${[90, 135, 180, 225, 270]
      .map(
        (deg) =>
          `<path d="M${at(216, 256, 128, deg)} L${at(216, 256, 180, deg)}"/>`,
      )
      .join("")}</g>`,
    primary:
      '<circle cx="216" cy="256" r="80"/><rect x="216" y="232" width="272" height="48" rx="24"/>',
  }),
  // Containers of salvaged material: the front one marked for recycling,
  // the ribbed ones stacked behind it.
  [HardpointCategoryEnum.SALVAGE_STORAGE]: knockout({
    defs:
      mask(
        "ribs",
        `<path d="M240 40 L240 232 M320 40 L320 232 M400 40 L400 232 M424 272 L424 472" stroke="#000" stroke-width="${GAP}"/>`,
      ) +
      mask(
        "recycle",
        `<g color="#000" style="--fa-primary-color: #000" transform="translate(192 344) scale(0.6) translate(-256 -256)">${RECYCLE}</g>`,
      ),
    secondary:
      '<g mask="url(#{id}-ribs)"><rect x="160" y="40" width="320" height="192" rx="20"/><rect x="376" y="272" width="104" height="200" rx="20"/></g>',
    primary:
      '<rect x="32" y="208" width="320" height="264" rx="24" mask="url(#{id}-recycle)"/>',
  }),
  // A shield, halved.
  [HardpointCategoryEnum.ARMOR]: knockout({
    secondary: `<path d="${SHIELD_RIGHT}"/>`,
    primary: `<path d="${SHIELD_LEFT}" transform="translate(-${GAP / 2} 0)"/>`,
  }),
  // A shield, quartered.
  [HardpointCategoryEnum.COUNTERMEASURES]: knockout({
    defs: mask(
      "quarters",
      `<path d="M256 0 L256 512 M0 248 L512 248" stroke="#000" stroke-width="${GAP * 2}"/>`,
    ),
    secondary: `<path d="${SHIELD}" mask="url(#{id}-quarters)"/>`,
    primary: `<g mask="url(#{id}-quarters)"><path d="M256 32 L80 96 Q64 102 64 120 L64 248 L256 248 Z"/><path d="M256 248 L448 248 C448 360 368 440 256 480 Z"/></g>`,
  }),
  [HardpointCategoryEnum.SELFDESTRUCT]: knockout({
    defs: mask(
      "warning",
      '<rect x="234" y="172" width="44" height="108" rx="22" fill="#000"/><circle cx="256" cy="332" r="24" fill="#000"/>',
    ),
    secondary: secondary(star(12, 232, 172), 12),
    primary: '<circle cx="256" cy="256" r="124" mask="url(#{id}-warning)"/>',
  }),
  [HardpointCategoryEnum.LIFESUPPORT]: knockout({
    secondary:
      '<path d="M256 464 C120 368 40 288 40 184 C40 112 96 64 160 64 C208 64 240 96 256 120 C272 96 304 64 352 64 C416 64 472 112 472 184 C472 288 392 368 256 464 Z"/>',
    primary: `<path d="M32 264 L168 264 L208 184 L264 360 L312 224 L344 264 L480 264" ${PRIMARY_LINE}/>`,
  }),
  [HardpointCategoryEnum.BATTERIES]: knockout({
    secondary: '<rect x="24" y="120" width="408" height="272" rx="48"/>',
    primary:
      '<rect x="440" y="200" width="56" height="112" rx="20"/><rect x="88" y="184" width="80" height="144" rx="16"/><rect x="192" y="184" width="80" height="144" rx="16"/><rect x="296" y="184" width="80" height="144" rx="16"/>',
  }),
  // The original crane, traced: the gantry above, split off from the housing
  // and the hook hanging below it.
  [HardpointCategoryEnum.UTILITY]: {
    defs:
      mask(
        "gantry",
        '<rect x="0" y="147" width="512" height="365" fill="#000"/>',
      ) +
      mask("hook", '<rect x="0" y="0" width="512" height="164" fill="#000"/>'),
    secondary: `<path d="${CRANE}" fill-rule="evenodd" mask="url(#{id}-gantry)"/>`,
    primary: `<path d="${CRANE}" fill-rule="evenodd" mask="url(#{id}-hook)"/>`,
  },
  // The pod as it stands in a hangar: its front face between two angled
  // ones, the rims and corner brackets that hold them, and the warning mark.
  [HardpointCategoryEnum.ORE_PODS]: knockout({
    defs: mask(
      "warning",
      primary("M312 312 L336 352 L288 352 Z", 6).replace(
        PRIMARY_STROKE,
        'fill="#000" stroke="#000"',
      ),
    ),
    secondary: `${secondary("M72 120 L136 104 L136 408 L72 392 Z", 8)}${secondary("M376 104 L440 120 L440 392 L376 408 Z", 8)}<rect x="160" y="104" width="192" height="304" rx="10" mask="url(#{id}-warning)"/>`,
    primary: `${primary("M104 40 L408 40 L448 72 L448 88 L64 88 L64 72 Z", 12)}${primary("M64 424 L448 424 L448 440 L408 472 L104 472 L64 440 Z", 12)}${[
      148, 364,
    ]
      .map(
        (x) =>
          `<rect x="${x - 20}" y="28" width="40" height="76" rx="10"/><rect x="${x - 20}" y="408" width="40" height="76" rx="10"/>`,
      )
      .join("")}`,
  }),
  // A seat side on, facing right, on its pedestal.
  [HardpointCategoryEnum.SEAT]: knockout({
    secondary:
      '<rect x="216" y="352" width="80" height="96" rx="12"/><rect x="120" y="440" width="272" height="48" rx="24"/>',
    primary:
      '<rect x="80" y="32" width="104" height="296" rx="40"/><rect x="96" y="264" width="336" height="96" rx="36"/>',
  }),
  // A switch that routes power across a gap.
  [HardpointCategoryEnum.RELAY]: knockout({
    secondary: `<g ${SECONDARY_LINE}><path d="M32 344 L120 344"/><path d="M392 344 L480 344"/></g>`,
    primary: `<path d="M152 344 L352 160" ${PRIMARY_LINE}/><circle cx="152" cy="344" r="52"/><circle cx="360" cy="344" r="52"/>`,
  }),
  [HardpointCategoryEnum.PAINTS]: knockout({
    secondary: `<path d="M408 112 L464 112 L464 232 L256 272 L256 312" ${SECONDARY_LINE}/>`,
    primary:
      '<rect x="40" y="40" width="368" height="136" rx="40"/><rect x="212" y="296" width="88" height="184" rx="32"/>',
  }),
  // A door standing open in its frame.
  [HardpointCategoryEnum.DOORS]: knockout({
    defs: mask("knob", '<circle cx="272" cy="272" r="24" fill="#000"/>'),
    secondary: `<path d="M320 56 L392 56 Q416 56 416 80 L416 464 M48 472 L464 472" ${SECONDARY_LINE}/>`,
    primary:
      '<path d="M128 72 Q128 56 144 52 L304 24 Q320 22 320 40 L320 472 Q320 488 304 486 L144 456 Q128 452 128 436 Z" mask="url(#{id}-knob)"/>',
  }),
  // Crates stacked on the grid that holds them.
  [HardpointCategoryEnum.CARGOGRID]: knockout({
    secondary: '<rect x="24" y="432" width="464" height="56" rx="24"/>',
    primary:
      '<rect x="56" y="264" width="184" height="144" rx="24"/><rect x="272" y="264" width="184" height="144" rx="24"/><rect x="164" y="96" width="184" height="144" rx="24"/>',
  }),
  // A locker standing open: its frame, boxes on the shelf, a hanger on the
  // rail below, and the door swung out on its hinge.
  [HardpointCategoryEnum.INVENTORY]: knockout({
    defs:
      mask(
        "frame",
        '<rect x="108" y="60" width="168" height="392" rx="8" fill="#000"/>',
      ) +
      mask(
        "door",
        `<g stroke="#000" stroke-width="16" stroke-linecap="round"><path d="M352 112 L412 96 M352 148 L412 132 M352 184 L412 168"/><path d="M416 236 L416 304"/></g>`,
      ),
    secondary: '<rect x="108" y="60" width="168" height="392" rx="8"/>',
    primary: `<rect x="72" y="24" width="240" height="464" rx="28" mask="url(#{id}-frame)"/><rect x="108" y="168" width="168" height="24"/><rect x="128" y="96" width="72" height="72" rx="12"/><rect x="212" y="120" width="44" height="48" rx="10"/><rect x="108" y="232" width="168" height="20"/><path d="M192 252 L192 280 L252 324 L132 324 L192 280" ${line(PRIMARY_STROKE, 22)}/><g mask="url(#{id}-door)">${primary("M332 56 L440 24 L440 488 L332 456 Z", 12)}</g>`,
  }),
  [HardpointCategoryEnum.CONTROLLER]: knockout({
    secondary: `<g ${SECONDARY_LINE}><path d="M48 128 L464 128"/><path d="M48 256 L464 256"/><path d="M48 384 L464 384"/></g>`,
    primary:
      '<rect x="128" y="64" width="72" height="128" rx="28"/><rect x="304" y="192" width="72" height="128" rx="28"/><rect x="200" y="320" width="72" height="128" rx="28"/>',
  }),
  [HardpointCategoryEnum.UNKNOWN]: knockout({
    secondary: '<circle cx="256" cy="256" r="240"/>',
    primary: `<path d="M184 200 Q184 128 256 128 Q328 128 328 192 Q328 240 280 264 Q256 276 256 312 L256 320" ${line(PRIMARY_STROKE, 52)}/><circle cx="256" cy="396" r="34"/>`,
  }),
};
