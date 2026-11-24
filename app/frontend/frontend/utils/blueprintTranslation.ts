import { MAX_NAME_LENGTH, plainText, readText } from "./blueprintLog";

// A translation's `global.ini` is lines of `key=text`, the key with a `,P`
// where the text carries a placeholder. It holds both what the game announces a
// blueprint with and the name it shows for every item.
const NOTIFICATION_KEY = "crafting_hud_notification_received_blueprint";
const PLACEHOLDER = "%s";

// What the API accepts per name.
export const MAX_KEYS = 100;

export interface BlueprintTranslation {
  markers: string[];
  keysByName: Map<string, string[]>;
}

export interface BlueprintNameKeys {
  name: string;
  keys: string[];
}

const nameKey = (name: string) =>
  plainText(name.normalize("NFKC").replace(/["'‘’“”`]/g, "")).toLowerCase();

const readLine = (line: string, translation: BlueprintTranslation) => {
  const separator = line.indexOf("=");

  if (separator < 1) return;

  const key = line
    .slice(0, separator)
    .replace(/^\uFEFF/, "")
    .trim()
    .replace(/,P$/, "")
    .toLowerCase();
  const text = line.slice(separator + 1);

  if (key === NOTIFICATION_KEY) {
    const placeholder = text.indexOf(PLACEHOLDER);
    const marker = placeholder < 0 ? "" : plainText(text.slice(0, placeholder));

    if (marker && !translation.markers.includes(marker)) {
      translation.markers.push(marker);
    }

    return;
  }

  // Everything else in the file is prose; a name is looked up among names.
  if (
    !key.includes("name") &&
    !key.startsWith("mission_item") &&
    !key.startsWith("item_")
  ) {
    return;
  }

  if (key.length > MAX_NAME_LENGTH || text.length > MAX_NAME_LENGTH) return;

  const name = nameKey(text);

  if (!name) return;

  const keys = translation.keysByName.get(name);

  if (!keys) {
    translation.keysByName.set(name, [key]);
  } else if (keys.length < MAX_KEYS && !keys.includes(key)) {
    keys.push(key);
  }
};

export const readBlueprintTranslations = async (
  files: Blob[],
): Promise<BlueprintTranslation> => {
  const translation: BlueprintTranslation = {
    markers: [],
    keysByName: new Map(),
  };

  for (const file of files) {
    await readText(file, (line) => readLine(line, translation));
  }

  return translation;
};

export const nameKeysFor = (
  names: string[],
  { keysByName }: BlueprintTranslation,
): BlueprintNameKeys[] =>
  names.flatMap((name) => {
    const keys = keysByName.get(nameKey(name));

    return keys ? [{ name, keys }] : [];
  });
