import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import type { RouteLocationNormalized } from "vue-router";
import { restoreSavedFilter, useFiltersStore } from "./filters";

const location = (path: string, query: Record<string, string> = {}) =>
  ({
    path,
    query,
    hash: "",
    matched: [{ path }],
  }) as unknown as RouteLocationNormalized;

const firstLoad = {
  path: "/",
  query: {},
  hash: "",
  matched: [],
} as unknown as RouteLocationNormalized;

beforeEach(() => {
  setActivePinia(createPinia());

  useFiltersStore().saveFilter("/ships/", {
    query: { manufacturerIn: ["rsi"], s: "name asc" },
    viewKeys: ["t"],
  });
});

describe("restoreSavedFilter", () => {
  it("brings the filter back to a list arrived at without one", () => {
    expect(restoreSavedFilter(location("/ships"), location("/hangar"))).toEqual(
      {
        path: "/ships",
        hash: "",
        query: { manufacturerIn: ["rsi"], s: "name asc" },
      },
    );
  });

  it("brings it back on the first load too", () => {
    expect(restoreSavedFilter(location("/ships/"), firstLoad)?.query).toEqual({
      manufacturerIn: ["rsi"],
      s: "name asc",
    });
  });

  it("lets a link's own filter win", () => {
    expect(
      restoreSavedFilter(
        location("/ships", { searchCont: "carrack" }),
        location("/hangar"),
      ),
    ).toBeUndefined();
  });

  it("keeps the view a link did carry", () => {
    expect(
      restoreSavedFilter(
        location("/ships", { t: "archive", tab: "grid" }),
        location("/hangar"),
      )?.query,
    ).toEqual({
      manufacturerIn: ["rsi"],
      s: "name asc",
      t: "archive",
      tab: "grid",
    });
  });

  it("lets a link's own sort or page win", () => {
    expect(
      restoreSavedFilter(
        location("/ships", { s: "scu desc" }),
        location("/hangar"),
      ),
    ).toBeUndefined();
    expect(
      restoreSavedFilter(
        location("/ships", { page: "3" }),
        location("/hangar"),
      ),
    ).toBeUndefined();
  });

  it("lets its own redirect through, even when only a sort was saved", () => {
    useFiltersStore().saveFilter("/ships", {
      query: { s: "name asc" },
      viewKeys: [],
    });

    const restored = restoreSavedFilter(
      location("/ships"),
      location("/hangar"),
    );

    expect(restored?.query).toEqual({ s: "name asc" });
    expect(
      restoreSavedFilter(
        location(
          restored?.path ?? "",
          restored?.query as Record<string, string>,
        ),
        location("/hangar"),
      ),
    ).toBeUndefined();
  });

  it("leaves a cleared filter cleared within the list", () => {
    expect(
      restoreSavedFilter(
        location("/ships/"),
        location("/ships", { manufacturerIn: "rsi" }),
      ),
    ).toBeUndefined();
  });

  it("leaves a list nothing was saved for alone", () => {
    expect(
      restoreSavedFilter(location("/components"), location("/hangar")),
    ).toBeUndefined();
  });
});
