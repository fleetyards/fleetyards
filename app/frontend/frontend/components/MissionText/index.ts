/**
 * The two kinds of markup the game's own strings carry, split into pieces a
 * template can render.
 *
 * A mission title or description is a template the game fills in when it
 * generates the mission, so what we hold is never the finished sentence:
 *
 *   ~mission(Location|Address)  a run-time substitution; 902 of 2472 titles
 *                               and 2344 of 2475 descriptions carry one
 *   <EM4>...</EM4>              the game's own emphasis, 3567 times across
 *                               the localisation file -- and four of those
 *                               opens never close
 *
 * Deleting a span breaks the sentence around it ("head on over to , destroy a
 * few things"), so each becomes a token carrying the parameter's name instead.
 * The emphasis becomes emphasis. Neither is ever passed to `v-html`: this is
 * text written by a third party, and the four unbalanced tags are proof enough
 * that it cannot be trusted to be well formed.
 */
export type MissionTextPart = {
  kind: "text" | "token" | "emphasis";
  value: string;
};

// Non-greedy and bounded by the closing bracket: a description carries several,
// and a greedy match would swallow the prose between two of them.
const PLACEHOLDER = /~mission\(([^)]*)\)/g;

// Any `EM` level -- EM, EM2, EM4 all appear -- and non-greedy, so two emphasised
// runs in one paragraph stay two.
const EMPHASIS = /<EM\d*>([\s\S]*?)<\/EM\d*>/g;

// Whatever an unbalanced tag leaves behind. Four opens in the current build
// never close, and their text would otherwise read with the tag in it.
const STRAY_TAG = /<\/?EM\d*>/g;

/**
 * The parameter as a reader would name it. `~mission(Location|Address)` is the
 * address of a location, and the part before the pipe is the noun worth
 * showing -- the rest names which of its fields the game will substitute.
 */
const tokenLabel = (parameter: string) =>
  (parameter.split("|")[0] || parameter).trim();

export const missionTextParts = (text?: string | null): MissionTextPart[] => {
  if (!text) return [];

  const parts: MissionTextPart[] = [];

  // Emphasis first, so a placeholder inside an emphasised run is still found:
  // the inner pass runs over each piece either way.
  let cursor = 0;

  EMPHASIS.lastIndex = 0;

  for (const match of text.matchAll(EMPHASIS)) {
    const at = match.index ?? 0;

    parts.push(...placeholderParts(text.slice(cursor, at), "text"));
    parts.push(...placeholderParts(match[1], "emphasis"));

    cursor = at + match[0].length;
  }

  parts.push(...placeholderParts(text.slice(cursor), "text"));

  return parts.filter((part) => part.value !== "");
};

const placeholderParts = (
  text: string,
  kind: "text" | "emphasis",
): MissionTextPart[] => {
  const parts: MissionTextPart[] = [];
  let cursor = 0;

  PLACEHOLDER.lastIndex = 0;

  for (const match of text.matchAll(PLACEHOLDER)) {
    const at = match.index ?? 0;

    parts.push({ kind, value: clean(text.slice(cursor, at)) });
    parts.push({ kind: "token", value: tokenLabel(match[1]) });

    cursor = at + match[0].length;
  }

  parts.push({ kind, value: clean(text.slice(cursor)) });

  return parts;
};

const clean = (text: string) => text.replace(STRAY_TAG, "");

/**
 * The same string with its spans removed rather than rendered, for the places
 * that can only take plain text -- a `title` attribute, a meta description.
 */
export const missionTextPlain = (text?: string | null) =>
  missionTextParts(text)
    .map((part) => (part.kind === "token" ? `[${part.value}]` : part.value))
    .join("");
