import { describe, expect, it, vi } from "vitest";

const route = { query: {} as Record<string, unknown> };

vi.mock("vue-router", async () => {
  const actual = await vi.importActual<Record<string, unknown>>("vue-router");

  return { ...actual, useRoute: () => route };
});

const { useFleetDirectoryFilters } =
  await import("@/frontend/composables/useFleetDirectoryFilters");

describe("useFleetDirectoryFilters", () => {
  it("sends a single value from the URL as a list", () => {
    route.query = {
      activityIn: "piracy",
      languageIn: ["de", "en"],
      search: "x",
    };

    expect(useFleetDirectoryFilters().getQuery()).toEqual({
      activityIn: ["piracy"],
      languageIn: ["de", "en"],
      search: "x",
    });
  });
});
