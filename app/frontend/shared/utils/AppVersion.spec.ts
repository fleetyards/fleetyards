import { describe, expect, it } from "vitest";
import { isNewerVersion } from "./AppVersion";

describe("isNewerVersion", () => {
  it("accepts a later release", () => {
    expect(isNewerVersion("v9.10.0", "v9.9.0")).toBe(true);
    expect(isNewerVersion("v10.0.0", "v9.9.9")).toBe(true);
    expect(isNewerVersion("9.9.1", "v9.9.0")).toBe(true);
  });

  it("refuses the same or an earlier release", () => {
    expect(isNewerVersion("v9.9.0", "v9.9.0")).toBe(false);
    expect(isNewerVersion("v9.8.0", "v9.9.0")).toBe(false);
    expect(isNewerVersion("v9.9.0", "v9.10.0")).toBe(false);
  });
});
