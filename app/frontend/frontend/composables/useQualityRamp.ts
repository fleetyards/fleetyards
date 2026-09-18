import { type BlueprintCostModifier } from "@/services/fyApi";

export type Segment = {
  from: number;
  to: number;
  a: number;
  b: number;
};

export type Ramp = {
  key: string;
  name: string;
  plotted: boolean;
  /** The stat as it comes out, or the bare factor where we hold no base. */
  headline?: string;
  /** What that figure is, at the neutral grade. Absent without a base. */
  base?: string;
  /** How far the current grade moves it, e.g. "+12.5%". */
  delta?: string;
  /** Whether that move is an improvement, by the ramp's own direction. */
  trend?: "better" | "worse" | "level";
  factor?: string;
  /** Printed only when it is not already the headline. */
  showFactor?: boolean;
  span?: string;
  domain?: string;
  points?: string;
  /** Placed over the plot rather than inside it -- see the marker note. */
  markerLeft?: string;
  markerTop?: string;
  neutralLeft?: string;
};

// The quality scale the game ramps a stat over.
const QUALITY_MIN = 0;
const QUALITY_MAX = 1000;

/**
 * Which way a stat improves.
 *
 * Better material makes a better item, so the direction a ramp moves over
 * quality is the direction the stat improves in -- and the files bear that
 * out: 22 of the 23 stats ramp one way only, and the four that fall are
 * exactly the ones where less is better (the three recoil stats and quantum
 * fuel burn). So the polarity is read off the ramp rather than guessed at or
 * kept in a hand-written list.
 */
export const trendOf = (shift: number, direction: number) => {
  const benefit = shift * Math.sign(direction);
  if (Math.abs(benefit) < 0.05) return "level" as const;

  return benefit > 0 ? ("better" as const) : ("worse" as const);
};

// Where every ramp in the build sits at 1.0x: the single-segment ones are
// symmetric about it, the piecewise ones put their seam there. It is the grade
// the catalogue's own figure describes.
export const NEUTRAL_QUALITY = 500;

// The plot's own box. Drawn wide and flat, then stretched to the row, so
// every coordinate out of it is a percentage of the rendered plot.
const WIDTH = 100;
const HEIGHT = 38;
const TOP = 4;
const BOTTOM = 34;

export const formatNumber = (value: number) =>
  value.toLocaleString(undefined, { maximumFractionDigits: 2 });

export const withUnit = (value: number, unit?: string | null) => {
  const figure = formatNumber(value);
  if (!unit) return figure;

  // A percentage reads closed up; every other unit is a word after a space.
  return unit === "%" ? `${figure}%` : `${figure} ${unit}`;
};

/** The figures a stat ramps over, in quality order. Empty where it has none. */
export const segmentsOf = (modifiers: BlueprintCostModifier[]): Segment[] =>
  modifiers
    .filter(
      (modifier) =>
        modifier.modifierAtStart !== undefined &&
        modifier.modifierAtStart !== null &&
        modifier.modifierAtEnd !== undefined &&
        modifier.modifierAtEnd !== null,
    )
    .map((modifier) => ({
      from: modifier.startQuality ?? QUALITY_MIN,
      to: modifier.endQuality ?? QUALITY_MAX,
      a: modifier.modifierAtStart as number,
      b: modifier.modifierAtEnd as number,
    }))
    .sort((one, other) => one.from - other.from);

/**
 * Where the multiplier sits at one quality. Outside its own domain a ramp
 * holds its end value, which is what the flat lead-in and tail draw.
 */
export const valueAt = (segments: Segment[], at: number) => {
  for (const segment of segments) {
    if (at <= segment.to) {
      const span = segment.to - segment.from;
      const t = span <= 0 ? 1 : (at - segment.from) / span;

      return segment.a + (segment.b - segment.a) * Math.max(t, 0);
    }
  }

  return segments[segments.length - 1].b;
};

/** Modifiers grouped by the stat they move, in the order they first appear. */
export const byStat = (modifiers: BlueprintCostModifier[]) => {
  const groups = new Map<string, BlueprintCostModifier[]>();

  modifiers.forEach((modifier) => {
    const key = modifier.propertyKey || modifier.name || "";
    groups.set(key, [...(groups.get(key) || []), modifier]);
  });

  return groups;
};

/**
 * What better material in one slot buys, as a figure and a shape.
 *
 * A modifier ramps one stat linearly over material quality. A stat can carry
 * several, and 1,007 of them in the current build do: contiguous segments, up
 * to seven, which together are a curve rather than a line. They are grouped by
 * stat here so a stat reads as one row whichever shape it has.
 *
 * Where the catalogue holds the crafted item's own figure for the stat, the
 * factor is applied to it and the row leads with the result -- which is the
 * question being asked -- rather than with the multiplier.
 */
export const useQualityRamp = (
  modifiers: MaybeRefOrGetter<BlueprintCostModifier[]>,
  quality: MaybeRefOrGetter<number>,
  reachable: MaybeRefOrGetter<boolean>,
) => {
  // Drawn across the whole quality scale rather than only the ramp's own
  // stretch of it. 249 stats in the build start at quality 500, and a line
  // that began there left the marker floating beside it below that point.
  const shape = (segments: Segment[]) => {
    const values = segments.flatMap((segment) => [segment.a, segment.b]);
    const lo = Math.min(...values);
    const hi = Math.max(...values);
    const range = hi - lo || 1;

    const x = (at: number) => (at / QUALITY_MAX) * WIDTH;
    const y = (value: number) =>
      BOTTOM - ((value - lo) / range) * (BOTTOM - TOP);

    const first = segments[0];
    const last = segments[segments.length - 1];
    const points: string[] = [];

    if (first.from > QUALITY_MIN) points.push(`0,${y(first.a).toFixed(1)}`);

    // Both ends of every segment, so a discontinuity would be drawn rather
    // than quietly straightened into one that is not there.
    segments.forEach((segment) => {
      points.push(`${x(segment.from).toFixed(1)},${y(segment.a).toFixed(1)}`);
      points.push(`${x(segment.to).toFixed(1)},${y(segment.b).toFixed(1)}`);
    });

    if (last.to < QUALITY_MAX) points.push(`${WIDTH},${y(last.b).toFixed(1)}`);

    return { points: points.join(" "), x, y, from: first.from, to: last.to };
  };

  const ramps = computed<Ramp[]>(() => {
    const all = toValue(modifiers);
    const at = toValue(quality);

    return [...byStat(all).entries()].map(([key, group]) => {
      const name = group[0].name || key;
      const unit = group[0].unit;
      const base = group[0].baseValue;

      const segments = segmentsOf(group);

      // A stat the game names and gives no figures for. 598 modifiers are in
      // exactly that position, and they are not an error.
      if (!segments.length) {
        return { key, name, plotted: false };
      }

      const { points, x, y, from, to } = shape(segments);
      const now = valueAt(segments, at);
      const factor = `${now.toFixed(3)}×`;

      // 2,060 of the build's modifiers move a stat the catalogue holds no
      // figure for -- component health, weapon recoil, quantum fuel burn --
      // and there the multiplier is the whole answer.
      const hasBase = base !== undefined && base !== null;
      const shift = (now - 1) * 100;
      const direction = segments[segments.length - 1].b - segments[0].a;

      return {
        key,
        name,
        plotted: true,
        headline: hasBase ? withUnit(base * now, unit) : factor,
        base: hasBase ? withUnit(base, unit) : undefined,
        delta: `${shift > 0 ? "+" : ""}${shift.toFixed(1)}%`,
        trend: trendOf(shift, direction),
        factor,
        // The domain comes off the segments. Claiming Q0–1000 for a stat that
        // only starts at 500 would state a range the files do not.
        span: `${segments[0].a.toFixed(2)}× → ${segments[segments.length - 1].b.toFixed(2)}×`,
        domain: `Q${from}–${to}`,
        showFactor: hasBase,
        points,
        // The plot is stretched to the row, which would pull a marker drawn
        // inside it into an ellipse -- the stretch distorts geometry, not just
        // stroke width. So the marker is positioned over the plot instead, and
        // these are percentages of it.
        markerLeft: `${((x(at) / WIDTH) * 100).toFixed(2)}%`,
        markerTop: `${((y(now) / HEIGHT) * 100).toFixed(2)}%`,
        neutralLeft: `${((x(NEUTRAL_QUALITY) / WIDTH) * 100).toFixed(2)}%`,
        usable: toValue(reachable),
      };
    });
  });

  return { ramps };
};
