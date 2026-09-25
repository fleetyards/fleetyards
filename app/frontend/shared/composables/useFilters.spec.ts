import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";

const query = ref<Record<string, string>>({});
// The composable chains `.catch` onto every navigation.
const replace = vi.fn().mockResolvedValue(undefined);

vi.mock("vue-router", () => ({
  useRoute: () => ({ query: query.value, path: "/hangar/inventories/main" }),
  useRouter: () => ({ replace, push: vi.fn() }),
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

/*
 * View state is not a filter, so `getQuery` drops it -- but it is still where
 * the reader is, and these navigations are made with that same stripped query.
 * Filtering an invite list dropped `?view=invites` and the page fell back to
 * the roster under the reader.
 */
describe("useFilters navigation", () => {
  beforeEach(() => {
    replace.mockClear();
  });

  it("keeps the view somebody is filtering in", async () => {
    query.value = { view: "invites", tab: "log", direction: "outgoing" };

    useFilters().filter({ nameCont: "ti" } as never);
    await vi.waitFor(() => expect(replace).toHaveBeenCalled());

    expect(replace.mock.calls[0][0].query).toMatchObject({
      nameCont: "ti",
      view: "invites",
      tab: "log",
      direction: "outgoing",
    });
  });

  it("keeps it when the filters are cleared", () => {
    query.value = { view: "invites", direction: "outgoing", nameCont: "ti" };

    useFilters().resetFilter();

    expect(replace).toHaveBeenCalledWith(
      expect.objectContaining({
        query: { view: "invites", direction: "outgoing" },
      }),
    );
  });

  it("keeps a list's own view keys when the filters are cleared", () => {
    query.value = { t: "archive", s: "bogus asc", tab: "log" };

    useFilters({ viewKeys: ["t"] }).resetFilter();

    expect(replace).toHaveBeenCalledWith(
      expect.objectContaining({ query: { t: "archive", tab: "log" } }),
    );
  });

  it("has nothing to reset when the route holds only view state", () => {
    query.value = { t: "archive", tab: "log" };

    expect(useFilters({ viewKeys: ["t"] }).hasResettableQuery.value).toBe(
      false,
    );
    expect(useFilters().hasResettableQuery.value).toBe(true);
  });
});
