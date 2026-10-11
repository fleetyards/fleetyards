import { describe, expect, it } from "vitest";
import { renameTableCols } from "./renamedTableCols";

describe("renameTableCols", () => {
  const renames = { minCrew: "crew", maxCrew: "crew" } as const;

  it("swaps an old key for its replacement", () => {
    expect(renameTableCols(["name", "minCrew"], renames)).toEqual([
      "name",
      "crew",
    ]);
  });

  it("keeps one column when two old keys share a replacement", () => {
    expect(renameTableCols(["minCrew", "maxCrew"], renames)).toEqual(["crew"]);
  });

  it("leaves a choice with no old keys alone", () => {
    expect(renameTableCols(["name", "crew"], renames)).toEqual([
      "name",
      "crew",
    ]);
  });
});
