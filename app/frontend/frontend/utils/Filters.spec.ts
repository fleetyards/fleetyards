import { describe, expect, it } from "vitest";
import { keptOptions } from "./Filters";

const options = [{ value: "1" }, { value: "2" }];

describe("keptOptions", () => {
  it("drops the picks the options no longer have", () => {
    expect(keptOptions(["1", "3"], options)).toEqual(["1"]);
  });

  it("leaves a selection that still fits alone", () => {
    expect(keptOptions(["2"], options)).toBeUndefined();
  });

  it("waits for an answer before narrowing", () => {
    expect(keptOptions(["3"], undefined)).toBeUndefined();
  });

  it("empties a selection when nothing is left to pick", () => {
    expect(keptOptions(["1"], [])).toEqual([]);
  });
});
