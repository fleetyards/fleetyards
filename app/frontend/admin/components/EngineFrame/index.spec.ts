import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./index.vue";

const Page = defineComponent({ render: () => h("div") });

const mount = async (query: Record<string, string> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/jobs/", name: "workers", component: Page }],
  });

  await router.push({ name: "workers", query });
  await router.isReady();

  const wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { src: "/admin/workers", title: "Workers" },
    plugins: [router],
  });

  return { wrapper, router };
};

const loadFrame = async (
  wrapper: Awaited<ReturnType<typeof mount>>["wrapper"],
  href: string,
  frameWindow: object = {},
) => {
  const iframe = wrapper.find("iframe");
  const url = new URL(href, window.location.origin);

  Object.defineProperty(iframe.element, "contentWindow", {
    value: { location: url, ...frameWindow },
    configurable: true,
  });

  await iframe.trigger("load");
  await new Promise((resolve) => setTimeout(resolve));
};

describe("AdminEngineFrame", () => {
  beforeEach(() => {
    vi.stubGlobal(
      "ResizeObserver",
      class {
        observe() {}
        disconnect() {}
      },
    );
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("frames the engine's root", async () => {
    const { wrapper } = await mount();

    expect(wrapper.find("iframe").attributes("src")).toBe("/admin/workers");
  });

  it("comes back to the page kept in the query", async () => {
    const { wrapper } = await mount({ path: "/morgue" });

    expect(wrapper.find("iframe").attributes("src")).toBe(
      "/admin/workers/morgue",
    );
  });

  it("ignores a query path that would leave the host", async () => {
    const { wrapper } = await mount({ path: "//evil.example/x" });

    expect(wrapper.find("iframe").attributes("src")).toBe("/admin/workers");
  });

  it("keeps where the frame went in the query", async () => {
    const { wrapper, router } = await mount();

    await loadFrame(wrapper, "/admin/workers/retries?page=2");

    expect(router.currentRoute.value.query.path).toBe("/retries?page=2");
    expect(wrapper.find("iframe").attributes("src")).toBe("/admin/workers");
  });

  it("drops the query back at the engine's root", async () => {
    const { wrapper, router } = await mount({ path: "/morgue" });

    await loadFrame(wrapper, "/admin/workers/");

    expect(router.currentRoute.value.query.path).toBeUndefined();
  });

  const stubAssign = () => {
    const assign = vi.fn();
    vi.spyOn(window, "location", "get").mockReturnValue({
      ...window.location,
      assign,
    });

    return assign;
  };

  it("hands the admin app to the window when Rails turns the engine down", async () => {
    const { wrapper } = await mount();
    const assign = stubAssign();

    await loadFrame(wrapper, "/admin/workers/retries", { ON_SUBDOMAIN: false });

    expect(assign).toHaveBeenCalledWith("/admin/workers/retries");
  });

  it("leaves a frame it cannot read alone", async () => {
    const { wrapper, router } = await mount({ path: "/morgue" });
    const assign = stubAssign();
    const iframe = wrapper.find("iframe");

    Object.defineProperty(iframe.element, "contentWindow", {
      value: {
        get location() {
          throw new DOMException("Blocked a frame", "SecurityError");
        },
      },
      configurable: true,
    });
    await iframe.trigger("load");

    expect(assign).not.toHaveBeenCalled();
    expect(router.currentRoute.value.query.path).toBe("/morgue");
  });

  it("opens a link to another site outside the admin", async () => {
    const open = vi.spyOn(window, "open").mockReturnValue(null);
    const { wrapper } = await mount();
    const doc = document.implementation.createHTMLDocument();
    doc.body.innerHTML =
      '<a id="out" href="https://sidekiq.org/">x</a><a id="in" href="/admin/workers/busy">y</a><a id="mail" href="mailto:a@b.c">z</a>';
    Object.defineProperty(wrapper.find("iframe").element, "contentDocument", {
      value: doc,
      configurable: true,
    });

    await loadFrame(wrapper, "/admin/workers/");
    doc.getElementById("in")!.click();
    doc.getElementById("mail")!.click();
    doc.getElementById("out")!.click();

    expect(open).toHaveBeenCalledTimes(1);
    expect(open).toHaveBeenCalledWith(
      "https://sidekiq.org/",
      "_blank",
      "noopener",
    );
  });

  it("hands a page outside the engine to the window", async () => {
    const { wrapper } = await mount();
    const assign = stubAssign();

    await loadFrame(wrapper, "/admin/login");

    expect(assign).toHaveBeenCalledWith("/admin/login");
  });
});
