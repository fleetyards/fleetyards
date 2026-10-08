import { afterEach, describe, expect, it } from "vitest";
import {
  createMemoryHistory,
  createRouter,
  type LocationQueryRaw,
} from "vue-router";
import { createApp } from "vue";
import { createPinia } from "pinia";
import { usePaginationStore } from "@/shared/stores/pagination";
import { useFleetchartShareUrl } from "./useFleetchartShareUrl";

const shareUrlFor = async (
  path: string,
  query: LocationQueryRaw = {},
  savedPerPage?: number,
  shortPath?: string,
) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/:pathMatch(.*)*",
        name: "list",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ path, query });
  await router.isReady();

  const pinia = createPinia();
  if (savedPerPage) {
    usePaginationStore(pinia).setBykey("list", savedPerPage);
  }

  let result = "";
  const app = createApp({
    setup() {
      result = useFleetchartShareUrl(shortPath).value;

      return () => null;
    },
  });
  app.use(pinia);
  app.use(router);
  app.mount(document.createElement("div"));
  app.unmount();

  return new URL(result);
};

describe("useFleetchartShareUrl", () => {
  it("opens the chart on the current page", async () => {
    const url = await shareUrlFor("/hangar/ghost/");

    expect(url.origin).toBe(window.location.origin);
    expect(url.pathname).toBe("/hangar/ghost/");
    expect(url.searchParams.get("fleetchart")).toBe("true");
  });

  it("keeps the filters, sort and page", async () => {
    const url = await shareUrlFor("/ships/", {
      manufacturerIn: ["rsi", "anvil"],
      s: "name asc",
      page: "2",
    });

    expect(url.searchParams.getAll("manufacturerIn")).toEqual(["rsi", "anvil"]);
    expect(url.searchParams.get("s")).toBe("name asc");
    expect(url.searchParams.get("page")).toBe("2");
    expect(url.searchParams.get("fleetchart")).toBe("true");
  });

  it("does not repeat the flag when the chart was opened from a link", async () => {
    const url = await shareUrlFor("/hangar/ghost/wishlist/", {
      fleetchart: "true",
    });

    expect(url.searchParams.getAll("fleetchart")).toEqual(["true"]);
  });

  it("adds the page size the sender keeps for the list", async () => {
    const url = await shareUrlFor("/ships/", { page: "2" }, 120);

    expect(url.searchParams.get("perPage")).toBe("120");
  });

  it("passes on the page size of a link the sender followed", async () => {
    const url = await shareUrlFor("/ships/", { perPage: "60" }, 120);

    expect(url.searchParams.getAll("perPage")).toEqual(["60"]);
  });

  it("adds no page size when the sender never picked one", async () => {
    const url = await shareUrlFor("/ships/");

    expect(url.searchParams.has("perPage")).toBe(false);
  });

  it("keeps the filters on the page when no short domain is set", async () => {
    const url = await shareUrlFor(
      "/fleets/fleetyards/ships/",
      { manufacturerIn: ["rsi"] },
      undefined,
      "/f/FY/ships",
    );

    expect(url.origin).toBe(window.location.origin);
    expect(url.pathname).toBe("/fleets/fleetyards/ships/");
    expect(url.searchParams.getAll("manufacturerIn")).toEqual(["rsi"]);
    expect(url.searchParams.get("fleetchart")).toBe("true");
  });

  describe("with a short domain", () => {
    afterEach(() => {
      window.SHORT_DOMAIN = "";
    });

    it("carries the query on the short link", async () => {
      window.SHORT_DOMAIN = "fltyrd.net";

      const url = await shareUrlFor(
        "/hangar/ghost/",
        { manufacturerIn: ["rsi", "anvil"] },
        undefined,
        "/h/ghost",
      );

      expect(url.host).toBe("fltyrd.net");
      expect(url.pathname).toBe("/h/ghost");
      expect(url.searchParams.getAll("manufacturerIn")).toEqual([
        "rsi",
        "anvil",
      ]);
      expect(url.searchParams.get("fleetchart")).toBe("true");
    });

    it("stays on the page for a list without a short path", async () => {
      window.SHORT_DOMAIN = "fltyrd.net";

      const url = await shareUrlFor("/ships/");

      expect(url.origin).toBe(window.location.origin);
      expect(url.pathname).toBe("/ships/");
    });
  });
});
