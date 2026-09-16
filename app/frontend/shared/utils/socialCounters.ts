/*
 * How X and Bluesky count, mirrored from Announcements::Platform so the live
 * counter in the editor and the count in the dry run give the same answer.
 *
 * Neither counts characters the way JavaScript does. X weights codepoints and
 * bills a URL at a flat 23; Bluesky counts grapheme clusters. `String.length`
 * is UTF-16 code units, which is a third answer again — it reports an emoji as
 * two and a CJK character as one, when X wants one-and-two respectively.
 */

const SCALE = 100;
const DEFAULT_WEIGHT = 200;
const LIGHT_WEIGHT = 100;

// The ranges twitter-text v3 gives a weight of 100.
const LIGHT_RANGES: [number, number][] = [
  [0, 4351],
  [8192, 8205],
  [8208, 8223],
  [8242, 8247],
];

const URL_LENGTH = 23;
const URL_PATTERN = /https?:\/\/\S+/g;

/*
 * X's extractor stops before trailing punctuation, so a sentence-final full
 * stop is text at its own weight rather than free inside the 23. Counting it
 * separately is both what X does and the safe direction to be wrong in.
 */
const URL_TRAILING = /[.,;:!?'"’”)\]}>]+$/;

// An emoji is one unit however many codepoints spell it.
const EMOJI_RANGES: [number, number][] = [
  [0x200d, 0x200d],
  [0xfe0f, 0xfe0f],
  [0x20e3, 0x20e3],
  [0x2190, 0x21ff],
  [0x2300, 0x23ff],
  [0x2600, 0x27bf],
  [0x2b00, 0x2bff],
  [0x1f000, 0x1faff],
];

const inRanges = (code: number, ranges: [number, number][]) =>
  ranges.some(([start, end]) => code >= start && code <= end);

const segmenter =
  typeof Intl !== "undefined" && "Segmenter" in Intl
    ? new Intl.Segmenter(undefined, { granularity: "grapheme" })
    : undefined;

export function graphemes(text: string): string[] {
  if (!segmenter) return [...text];

  return [...segmenter.segment(text)].map((entry) => entry.segment);
}

export function blueskyLength(text: string): number {
  return graphemes(text).length;
}

/*
 * Discord counts UTF-16 code units, which is exactly what a JavaScript string
 * length is. 2,000 rockets are 2,000 graphemes and 4,000 code units, and
 * Discord rejects the message.
 */
export function discordLength(text: string): number {
  return text.length;
}

function clusterWeight(cluster: string): number {
  const codes = [...cluster].map((char) => char.codePointAt(0) ?? 0);

  if (codes.some((code) => inRanges(code, EMOJI_RANGES))) return DEFAULT_WEIGHT;

  return codes.reduce(
    (total, code) =>
      total + (inRanges(code, LIGHT_RANGES) ? LIGHT_WEIGHT : DEFAULT_WEIGHT),
    0,
  );
}

export function xLength(text: string): number {
  if (!text) return 0;

  let weight = 0;
  let position = 0;

  for (const match of text.matchAll(URL_PATTERN)) {
    const start = match.index ?? 0;
    const url = match[0].replace(URL_TRAILING, "");

    // A match that was nothing but a scheme and punctuation is not a URL.
    if (!url) continue;

    if (start > position) {
      weight += graphemes(text.slice(position, start)).reduce(
        (total, cluster) => total + clusterWeight(cluster),
        0,
      );
    }

    weight += URL_LENGTH * SCALE;
    position = start + url.length;
  }

  if (position < text.length) {
    weight += graphemes(text.slice(position)).reduce(
      (total, cluster) => total + clusterWeight(cluster),
      0,
    );
  }

  return Math.floor(weight / SCALE);
}
