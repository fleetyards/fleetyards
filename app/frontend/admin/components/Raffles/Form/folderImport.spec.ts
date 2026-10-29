import { describe, expect, it } from "vitest";
import { parseRaffleText, readRaffleFolder } from "./folderImport";

const LOCALES = ["en", "de", "zh-CN"];

const BYTE_ORDER_MARK = String.fromCharCode(0xfeff);

const textFile = (name: string, content: string) =>
  new File([content], name, { type: "text/markdown" });

const image = (name: string, type = "image/jpeg") =>
  new File(["x"], name, { type });

describe("parseRaffleText", () => {
  it("reads title and prize from the front matter and the rest as description", () => {
    expect(
      parseRaffleText(
        '---\ntitle: Win a Centaurus!\nprize: "1x Centaurus: LTI"\n---\n\nFirst line.\n\nUp for grabs: [*ship:Constellation Mk V Centaurus*].\n',
      ),
    ).toEqual({
      title: "Win a Centaurus!",
      prize: "1x Centaurus: LTI",
      description:
        "First line.\n\nUp for grabs: [*ship:Constellation Mk V Centaurus*].",
    });
  });

  it("takes a file without front matter as the description only", () => {
    expect(parseRaffleText("Prize: a ship\n")).toEqual({
      description: "Prize: a ship",
    });
  });

  it("copes with Windows line endings and a byte order mark", () => {
    expect(
      parseRaffleText(
        `${BYTE_ORDER_MARK}---\r\ntitle: Titel\r\n---\r\nText\r\n`,
      ),
    ).toEqual({
      title: "Titel",
      description: "Text",
    });
  });

  it("ignores keys the form does not have", () => {
    expect(parseRaffleText("---\ntitle: T\ncode: SECRET\n---\n")).toEqual({
      title: "T",
    });
  });
});

describe("readRaffleFolder", () => {
  it("files texts by locale, images by name and skips the rest", async () => {
    const folder = await readRaffleFolder(
      [
        image("10-detail.png", "image/png"),
        textFile("EN.md", "---\ntitle: Win\n---\nText"),
        textFile("zh-cn.txt", "---\ntitle: 赢取\n---\n"),
        image("2-interior.jpg"),
        image("01-cover.webp", "image/webp"),
        image("logo.svg", "image/svg+xml"),
        textFile("notes.md", "draft"),
        textFile(".DS_Store", ""),
      ],
      LOCALES,
    );

    expect(folder.texts).toEqual({
      en: { title: "Win", description: "Text" },
      "zh-CN": { title: "赢取" },
    });
    expect(folder.images.map((file) => file.name)).toEqual([
      "01-cover.webp",
      "2-interior.jpg",
      "10-detail.png",
    ]);
    expect(folder.skipped).toEqual(["logo.svg", "notes.md"]);
  });
});
