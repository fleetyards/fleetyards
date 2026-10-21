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

/** What the files state for a placeholder, as the mission endpoints serve it. */
export type MissionTextValue = {
  token: string;
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

// A value can name a placeholder of its own -- "~mission(HydrogenFuel) SCU of
// Hydrogen Fuel" -- so filling runs again over what it put in. Bounded, so a
// value that names itself cannot loop.
const FILL_PASSES = 3;

const PLAIN_PLACEHOLDER = /~mission\(([^|)]*)\)/g;

const insideEmphasis = (before: string) =>
  (before.match(/<EM\d*>/g)?.length ?? 0) >
  (before.match(/<\/EM\d*>/g)?.length ?? 0);

/**
 * The text with every placeholder the files state a value for filled in. One
 * the game picks at run time -- a target, a location, any `Token|Field` -- is
 * left as written, for `missionTextParts` to name.
 */
export const fillMissionText = (
  text: string,
  values?: MissionTextValue[] | null,
) => {
  if (!values?.length) return text;

  const byToken = new Map(values.map((entry) => [entry.token, entry.value]));

  let filled = text;

  for (let pass = 0; pass < FILL_PASSES; pass += 1) {
    const next = filled.replace(
      PLAIN_PLACEHOLDER,
      (match, token: string, at: number, whole: string) => {
        const value = byToken.get(token.trim());

        if (value === undefined) return match;

        // Emphasis does not nest: a value bringing its own into an emphasised
        // run would close that run early.
        return insideEmphasis(whole.slice(0, at))
          ? value.replace(STRAY_TAG, "")
          : value;
      },
    );

    if (next === filled) break;

    filled = next;
  }

  return filled;
};

export const missionTextParts = (
  source?: string | null,
  values?: MissionTextValue[] | null,
): MissionTextPart[] => {
  if (!source) return [];

  const text = fillMissionText(source, values);

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
export const missionTextPlain = (
  text?: string | null,
  values?: MissionTextValue[] | null,
) =>
  missionTextParts(text, values)
    .map((part) => (part.kind === "token" ? `[${part.value}]` : part.value))
    .join("");
