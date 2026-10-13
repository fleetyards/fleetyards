import fontsScss from "@/stylesheets/shared/fonts.scss?raw";
import { toDataUrl } from "./dataUrl";

// dom-to-image embeds web fonts by reading `document.styleSheets`, but the
// stylesheet declaring them comes from the asset CDN, whose rules a page cannot
// read. The picture then fell back to system fonts while every box kept the
// size measured on screen, so the wider text wrapped over the lines below it.
// The plaque's faces are taken from their source instead, so the picture
// draws every subset the screen does.
const PLAQUE_FAMILIES = ["Orbitron", "Open Sans"];

const FONT_FILES = import.meta.glob<string>(
  "@/fonts/{orbitron,opensans}/*.woff2",
  { eager: true, query: "?url", import: "default" },
);

const fileUrl = (path: string) => {
  const name = path.split("/").pop();

  return Object.entries(FONT_FILES).find(([key]) =>
    key.endsWith(`/${name}`),
  )?.[1];
};

export const plaqueFontFaceRules = (source: string) =>
  (source.match(/@font-face\s*{[^}]*}/g) ?? []).filter((rule) =>
    PLAQUE_FAMILIES.some((family) => rule.includes(`"${family}"`)),
  );

const buildFontFaces = async (source: string) => {
  const rules = plaqueFontFaceRules(source);
  const paths = [
    ...new Set(rules.flatMap((rule) => rule.match(/@\/fonts\/[^)\s]+/g) ?? [])),
  ];

  const dataUrls = new Map(
    await Promise.all(
      paths.map(async (path) => {
        const url = fileUrl(path);
        if (!url) {
          throw new Error(`No font file for ${path}`);
        }

        return [path, await toDataUrl(url)] as const;
      }),
    ),
  );

  return rules
    .map((rule) =>
      rule.replace(/@\/fonts\/[^)\s]+/g, (path) => dataUrls.get(path) ?? path),
    )
    .join("")
    .replace(/\s+/g, " ");
};

let fontFaces: Promise<string> | undefined;

// The faces as one stylesheet with the files inlined, built once. Without them
// the picture is still drawn, in the fallback fonts.
export const plaqueFontFaces = (source = fontsScss) => {
  fontFaces ??= buildFontFaces(source).catch(() => {
    fontFaces = undefined;
    return "";
  });

  return fontFaces;
};

// Into the SVG dom-to-image draws, not the page: added to the document, the
// faces would replace the page's own while they load.
export const withFontFaces = (svgUri: string, css: string) => {
  if (!css) {
    return svgUri;
  }

  const head = svgUri.indexOf(">", svgUri.indexOf("<svg")) + 1;

  return `${svgUri.slice(0, head)}<style>${css}</style>${svgUri.slice(head)}`;
};
