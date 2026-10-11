import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";

const query = ref<Record<string, string>>({});
// The composable chains `.catch` onto every navigation.
const replace = vi.fn().mockResolvedValue(undefined);
const push = vi.fn().mockResolvedValue(undefined);
// What the history reports: the back and forward gestures only.
const historyListeners: (() => void)[] = [];

vi.mock("vue-router", () => ({
  useRoute: () => ({ query: query.value, path: "/hangar/inventories/main" }),
  useRouter: () => ({
    replace,
    push,
    options: {
      history: {
        listen: (listener: () => void) => {
          historyListeners.push(listener);

          return () => {};
        },
      },
    },
  }),
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

  it("drops the flag that opens the fleetchart", () => {
    query.value = { nameCont: "titanium", fleetchart: "true" };

    expect(useFilters().getQuery()).toEqual({ nameCont: "titanium" });
  });
});

/*
 * View state is not a filter, so `getQuery` drops it -- but it is still where
 * the reader is, and these navigations are made with that same stripped query.
 * Filtering an invite list dropped `?view=invites` and the page fell back to
 * the roster under the reader.
 */
// A filter changed right after arriving on the page counts as part of
// arriving; these are changes made once the page has settled.
const settled = (options?: Parameters<typeof useFilters>[0]) => {
  const filters = useFilters(options);

  vi.advanceTimersByTime(2000);

  return filters;
};

// Past the filter's debounce.
const debounced = () => vi.advanceTimersByTime(400);

describe("useFilters navigation", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    replace.mockClear();
    push.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("keeps the view somebody is filtering in", async () => {
    query.value = { view: "invites", tab: "log", direction: "outgoing" };

    settled().filter({ nameCont: "ti" } as never);
    debounced();

    expect(push.mock.calls[0][0].query).toMatchObject({
      nameCont: "ti",
      view: "invites",
      tab: "log",
      direction: "outgoing",
    });
  });

  it("starts a changed filter from the first page", async () => {
    query.value = { nameCont: "ti", page: "3" };

    settled().filter({ nameCont: "tit" } as never);
    debounced();

    expect(push.mock.calls[0][0].query.page).toBeUndefined();
  });

  it("keeps the page when the form writes back what the URL held", async () => {
    query.value = { activityIn: "piracy", page: "2" };

    settled().filter({ activityIn: ["piracy"] } as never);
    debounced();

    expect(replace.mock.calls[0][0].query.page).toBe("2");
  });

  it("keeps it when the filters are cleared", () => {
    query.value = { view: "invites", direction: "outgoing", nameCont: "ti" };

    void useFilters().resetFilter();

    expect(push).toHaveBeenCalledWith(
      expect.objectContaining({
        query: { view: "invites", direction: "outgoing" },
      }),
    );
  });

  it("keeps a list's own view keys when the filters are cleared", () => {
    query.value = { t: "archive", s: "bogus asc", tab: "log" };

    void useFilters({ viewKeys: ["t"] }).resetFilter();

    expect(push).toHaveBeenCalledWith(
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

  it("keeps a shared page size through a changed filter", async () => {
    query.value = { nameCont: "ti", page: "2", perPage: "120" };

    settled().filter({ nameCont: "tit" } as never);
    debounced();

    expect(push.mock.calls[0][0].query).toMatchObject({
      nameCont: "tit",
      perPage: "120",
    });
    expect(push.mock.calls[0][0].query.page).toBeUndefined();
  });

  // A reset goes back to the reader's own defaults, and is the way out of a
  // page size the API refused.
  it("drops a shared page size when the filters are cleared", () => {
    query.value = { nameCont: "ti", perPage: "120", tab: "log" };

    void useFilters().resetFilter();

    expect(push).toHaveBeenCalledWith(
      expect.objectContaining({ query: { tab: "log" } }),
    );
  });

  it("has nothing to reset when the route holds only a page size", () => {
    query.value = { perPage: "120" };

    expect(useFilters().hasResettableQuery.value).toBe(false);
  });

  it("is a step the back gesture can undo when the filter changed", async () => {
    query.value = { nameCont: "ti" };

    settled().filter({ nameCont: "tit" } as never);
    debounced();

    expect(replace).not.toHaveBeenCalled();
  });

  it("is no step at all when the form writes back what the URL held", async () => {
    query.value = { nameCont: "ti" };

    settled().filter({ nameCont: "ti" } as never);
    debounced();

    expect(push).not.toHaveBeenCalled();
  });

  it("folds one burst of typing into a single step", async () => {
    {
      query.value = { nameCont: "t" };
      const filters = settled();

      filters.filter({ nameCont: "ti" } as never);
      vi.advanceTimersByTime(400);
      query.value = { nameCont: "ti" };

      filters.filter({ nameCont: "tit" } as never);
      vi.advanceTimersByTime(400);

      expect(push).toHaveBeenCalledTimes(1);
      expect(replace).toHaveBeenCalledTimes(1);

      query.value = { nameCont: "tit" };
      vi.advanceTimersByTime(2000);
      filters.filter({ nameCont: "tita" } as never);
      vi.advanceTimersByTime(400);

      expect(push).toHaveBeenCalledTimes(2);
    }
  });

  it("adds no step for a change made right on arrival", () => {
    query.value = { nameCont: "ti" };

    useFilters().filter({ nameCont: "ti", readAtNull: "true" } as never);
    debounced();

    expect(push).not.toHaveBeenCalled();
    expect(replace).toHaveBeenCalledTimes(1);
  });

  it("adds no step for a change made right after a back gesture", () => {
    query.value = { nameCont: "ti" };
    const filters = settled();

    historyListeners.forEach((listener) => listener());
    filters.filter({ nameCont: "tit" } as never);
    debounced();

    expect(push).not.toHaveBeenCalled();
    expect(replace).toHaveBeenCalledTimes(1);
  });
});
