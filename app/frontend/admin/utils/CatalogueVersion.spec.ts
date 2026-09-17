import { describe, expect, it } from "vitest";
import { environmentOf, patchOf } from "./CatalogueVersion";

describe("patchOf", () => {
  it("drops the environment and the build id", () => {
    expect(patchOf("4.9.0-live.12344265")).toBe("4.9.0");
  });

  it("keeps a version that names no environment whole", () => {
    expect(patchOf("4.9.0")).toBe("4.9.0");
  });

  it("is undefined without a version", () => {
    expect(patchOf(null)).toBeUndefined();
    expect(patchOf(undefined)).toBeUndefined();
    expect(patchOf("")).toBeUndefined();
  });
});

describe("environmentOf", () => {
  it("reads the environment out of the version", () => {
    expect(environmentOf("4.9.0-live.12344265")).toBe("live");
    expect(environmentOf("4.10.1-ptu.12578875")).toBe("ptu");
  });

  it("reads a version that stops after the environment", () => {
    expect(environmentOf("4.10.1-ptu")).toBe("ptu");
  });

  it("is undefined when the version names none", () => {
    expect(environmentOf("4.9.0")).toBeUndefined();
    expect(environmentOf("4.9.0-")).toBeUndefined();
    expect(environmentOf(null)).toBeUndefined();
    expect(environmentOf(undefined)).toBeUndefined();
  });
});
