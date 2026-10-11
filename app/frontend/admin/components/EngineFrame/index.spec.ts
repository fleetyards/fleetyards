import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
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
) => {
  const iframe = wrapper.find("iframe");
  const url = new URL(href, "https://admin.example.test");

  Object.defineProperty(iframe.element, "contentWindow", {
    value: { location: url },
    configurable: true,
  });

  await iframe.trigger("load");
  await new Promise((resolve) => setTimeout(resolve));
};

describe("AdminEngineFrame", () => {
  afterEach(() => {
    vi.restoreAllMocks();
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

  it("hands a page outside the engine to the window", async () => {
    const assign = vi.fn();
    vi.spyOn(window, "location", "get").mockReturnValue({
      ...window.location,
      assign,
    });
    const { wrapper } = await mount();

    await loadFrame(wrapper, "/admin/login");

    expect(assign).toHaveBeenCalledWith("/admin/login");
  });
});
