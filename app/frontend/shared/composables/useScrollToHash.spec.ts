import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import { defineComponent, h } from "vue";
import { useScrollToHash } from "./useScrollToHash";

const Page = defineComponent({
  setup() {
    useScrollToHash();
    return () => h("div");
  },
});

const mountAt = async (path: string) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/ships/:slug/", component: Page }],
  });
  await router.push(path);
  await router.isReady();

  return mount(Page, {
    global: { plugins: [router] },
    attachTo: document.body,
  });
};

afterEach(() => {
  document.body.innerHTML = "";
});

describe("useScrollToHash", () => {
  it("scrolls to a section that renders after the page opened", async () => {
    const scrolled = vi.fn();
    const wrapper = await mountAt("/ships/andromeda/#paints");

    const section = document.createElement("div");
    section.id = "paints";
    section.scrollIntoView = scrolled;
    document.body.appendChild(section);
    await flushPromises();

    expect(scrolled).toHaveBeenCalledTimes(1);

    wrapper.unmount();
  });

  it("scrolls at once to a section that is already there", async () => {
    const scrolled = vi.fn();
    const section = document.createElement("div");
    section.id = "modules";
    section.scrollIntoView = scrolled;
    document.body.appendChild(section);

    const wrapper = await mountAt("/ships/andromeda/#modules");

    expect(scrolled).toHaveBeenCalledTimes(1);

    wrapper.unmount();
  });
});
