import { fileTypeMap } from "@/shared/components/DirectUpload/types";

export type RaffleFolderText = {
  title?: string;
  prize?: string;
  description?: string;
};

export type RaffleFolder = {
  texts: Record<string, RaffleFolderText>;
  images: File[];
  skipped: string[];
};

const TEXT_EXTENSIONS = ["md", "txt"];

const FRONT_MATTER_KEYS = ["title", "prize"] as const;

const splitName = (name: string) => {
  const dot = name.lastIndexOf(".");
  if (dot <= 0) return { base: name, extension: "" };

  return {
    base: name.slice(0, dot),
    extension: name.slice(dot + 1).toLowerCase(),
  };
};

const unquote = (value: string) => {
  const quoted = /^(["'])(.*)\1$/.exec(value);

  return quoted ? quoted[2] : value;
};

// A front matter block of `key: value` lines, then the description. Only the
// keys the form has are read, so a full YAML parser would buy nothing.
export const parseRaffleText = (source: string): RaffleFolderText => {
  const text = source.replace(/^\uFEFF/, "").replace(/\r\n?/g, "\n");
  const frontMatter = /^---\n([\s\S]*?)\n---[ \t]*(?:\n|$)/.exec(text);

  const result: RaffleFolderText = {};
  const body = frontMatter ? text.slice(frontMatter[0].length) : text;

  frontMatter?.[1].split("\n").forEach((line) => {
    const separator = line.indexOf(":");
    if (separator < 0) return;

    const key = line.slice(0, separator).trim().toLowerCase();
    const value = unquote(line.slice(separator + 1).trim());

    if ((FRONT_MATTER_KEYS as readonly string[]).includes(key) && value) {
      result[key as (typeof FRONT_MATTER_KEYS)[number]] = value;
    }
  });

  const description = body.trim();
  if (description) result.description = description;

  return result;
};

// Images keep the order of their file names, compared the way a file browser
// lists them, so `2.jpg` comes before `10.jpg` and `01-cover.jpg` leads.
const byName = (a: File, b: File) =>
  a.name.localeCompare(b.name, undefined, {
    numeric: true,
    sensitivity: "base",
  });

export const readRaffleFolder = async (
  files: File[],
  locales: string[],
): Promise<RaffleFolder> => {
  const localeByName = new Map(
    locales.map((locale) => [locale.toLowerCase(), locale]),
  );

  const folder: RaffleFolder = { texts: {}, images: [], skipped: [] };

  await Promise.all(
    files.map(async (file) => {
      if (file.name.startsWith(".")) return;

      const { base, extension } = splitName(file.name);
      const locale = localeByName.get(base.toLowerCase());

      if (locale && TEXT_EXTENSIONS.includes(extension)) {
        folder.texts[locale] = parseRaffleText(await file.text());
      } else if (fileTypeMap.image.includes(file.type)) {
        folder.images.push(file);
      } else {
        folder.skipped.push(file.name);
      }
    }),
  );

  folder.images.sort(byName);
  folder.skipped.sort();

  return folder;
};
