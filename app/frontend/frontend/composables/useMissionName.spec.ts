import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useMissionName } from "./useMissionName";

// `useI18n` reads the locale off a store, so the composable cannot be built
// at module scope.
beforeEach(() => {
  setActivePinia(createPinia());
});

const segments = (name: string) => useMissionName().segments(name);
const isTokenOnly = (name: string) => useMissionName().isTokenOnly(name);

const rendered = (name: string) =>
  segments(name)
    .map((segment) => (segment.slot ? `<${segment.text}>` : segment.text))
    .join("");

describe("useMissionName", () => {
  it("leaves a title the game already resolved alone", () => {
    expect(segments("Eliminate the Nine Tails")).toEqual([
      { text: "Eliminate the Nine Tails", slot: false },
    ]);
  });

  it("names what the game fills in", () => {
    expect(rendered("Keep ~mission(Location) Safe")).toBe(
      "Keep <location> Safe",
    );
  });

  it("handles a title that opens on a placeholder", () => {
    expect(rendered("~mission(TargetName) needs stomping")).toBe(
      "<target> needs stomping",
    );
  });

  // `Location|Address` and `TargetName|Last` narrow the wording, not the noun.
  it("reads the head of a piped token", () => {
    expect(rendered("Meet at ~mission(Location|Address)")).toBe(
      "Meet at <location>",
    );
  });

  it("falls back for a token it does not know", () => {
    expect(rendered("Do ~mission(Weather) things")).toBe("Do <varies> things");
  });

  it("carries several placeholders in one title", () => {
    expect(rendered("Protect ~mission(Objects) at ~mission(Location)")).toBe(
      "Protect <objects> at <location>",
    );
  });

  // 131 titles are nothing but an unresolved reference; the source's kind
  // says more than "a contract" on its own.
  it("recognises a title that is only a token", () => {
    expect(isTokenOnly("~mission(Contractor|RecoverItemTitle)")).toBe(true);
    expect(isTokenOnly("Wanted: ~mission(TargetName)")).toBe(false);
  });
});
