import { describe, expect, it, vi } from "vitest";
import { ref } from "vue";

const query = ref<Record<string, string>>({});

vi.mock("vue-router", () => ({
  useRoute: () => ({ query: query.value, path: "/hangar/inventories/main" }),
  useRouter: () => ({ replace: vi.fn(), push: vi.fn() }),
}));

const { useFilters } = await import("./useFilters");

describe("useFilters#getQuery", () => {
  it("keeps the filters", () => {
    query.value = { nameCont: "titanium", categoryEq: "commodity" };

    expect(useFilters().getQuery()).toEqual({
      nameCont: "titanium",
      categoryEq: "commodity",
    });
  });

  // The whole route query is spread into `q`, and the query schemas are
  // `additionalProperties: false` -- so anything in the URL that is not a
  // filter comes back a 400 that reads as a server error.
  it("drops pagination and view state, which are not filters", () => {
    query.value = {
      nameCont: "titanium",
      page: "3",
      perPage: "30",
      tab: "log",
    };

    expect(useFilters().getQuery()).toEqual({ nameCont: "titanium" });
  });
});
