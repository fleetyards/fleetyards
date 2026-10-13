/*
 * How Bluesky and Discord count, mirrored from Announcements::Platform so the
 * live counter in the editor and the count in the dry run give the same answer.
 *
 * Bluesky counts grapheme clusters, which `String.length` does not: it reports
 * an emoji as two UTF-16 code units.
 */

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
