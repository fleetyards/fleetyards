import { describe, expect, it } from "vitest";
import {
  createMemoryHistory,
  createRouter,
  type LocationQueryRaw,
} from "vue-router";
import { createApp } from "vue";
import { useFleetchartShareUrl } from "./useFleetchartShareUrl";

const shareUrlFor = async (path: string, query: LocationQueryRaw = {}) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/:pathMatch(.*)*", component: { template: "<div />" } }],
  });

  await router.push({ path, query });
  await router.isReady();

  let result = "";
  const app = createApp({
    setup() {
      result = useFleetchartShareUrl().value;

      return () => null;
    },
  });
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
});
