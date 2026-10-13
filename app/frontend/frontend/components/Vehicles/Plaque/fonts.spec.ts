import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

// Vitest blanks stylesheet imports, `?raw` ones included.
const fontsScss = readFileSync(
  resolve(__dirname, "../../../../stylesheets/shared/fonts.scss"),
  "utf8",
);

const loadFonts = async () => {
  vi.resetModules();
  return import("./fonts");
};

describe("plaqueFontFaceRules", () => {
  it("takes every Orbitron and Open Sans face, and no other", async () => {
    const { plaqueFontFaceRules } = await loadFonts();
    const rules = plaqueFontFaceRules(fontsScss);

    expect(rules.some((rule) => rule.includes('"Orbitron"'))).toBe(true);
    expect(
      rules.filter((rule) => rule.includes('"Open Sans"')).length,
    ).toBeGreaterThan(2);
    expect(rules.some((rule) => rule.includes("Dancing Script"))).toBe(false);
  });
});

describe("plaqueFontFaces", () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    vi.stubGlobal("fetch", fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    fetchMock.mockReset();
  });

  it("inlines every font file the faces refer to", async () => {
    fetchMock.mockImplementation(async () => new Response(new Blob(["font"])));
    const { plaqueFontFaces } = await loadFonts();

    const css = await plaqueFontFaces(fontsScss);

    expect(css).toContain('font-family: "Orbitron"');
    expect(css).toContain('font-family: "Open Sans"');
    expect(css).toContain("url(data:");
    expect(css).not.toContain("@/fonts/");
  });

  it("builds them once", async () => {
    fetchMock.mockImplementation(async () => new Response(new Blob(["font"])));
    const { plaqueFontFaces } = await loadFonts();

    await plaqueFontFaces(fontsScss);
    const calls = fetchMock.mock.calls.length;
    await plaqueFontFaces(fontsScss);

    expect(fetchMock).toHaveBeenCalledTimes(calls);
  });

  it("leaves the fonts out when a file cannot be fetched", async () => {
    fetchMock.mockImplementation(
      async () => new Response("Not Found", { status: 404 }),
    );
    const { plaqueFontFaces } = await loadFonts();

    expect(await plaqueFontFaces(fontsScss)).toBe("");
  });
});

describe("withFontFaces", () => {
  const svg =
    'data:image/svg+xml;charset=utf-8,<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><foreignObject></foreignObject></svg>';

  it("puts the faces at the top of the picture", async () => {
    const { withFontFaces } = await loadFonts();

    expect(withFontFaces(svg, "@font-face{}")).toBe(
      'data:image/svg+xml;charset=utf-8,<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><style>@font-face{}</style><foreignObject></foreignObject></svg>',
    );
  });

  it("leaves the picture alone without faces", async () => {
    const { withFontFaces } = await loadFonts();

    expect(withFontFaces(svg, "")).toBe(svg);
  });
});
