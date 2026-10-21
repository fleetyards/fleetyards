import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { search, type SearchGroup } from "@/services/fyApi";
import Component from "./index.vue";

let groups: SearchGroup[] = [];

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  search: vi.fn(async () => ({ groups })),
}));

const router = async () => {
  const blank = { template: "<div />" };
  const instance = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: blank },
      { path: "/ships", name: "ships", component: blank },
      { path: "/components/:slug", name: "component", component: blank },
      { path: "/locations/:slug", name: "location", component: blank },
    ],
  });

  await instance.push({ name: "home" });
  await instance.isReady();

  return instance;
};

type Wrapper = Awaited<ReturnType<typeof mountWithDefaults>>;

const typeInto = async (wrapper: Wrapper, text: string) => {
  await wrapper.find("input").setValue(text);
  await vi.advanceTimersByTimeAsync(300);
  await flushPromises();
};

const press = async (wrapper: Wrapper, key: string) => {
  await wrapper.find("form").trigger("keydown", { key });
};

const submit = async (wrapper: Wrapper) => {
  await wrapper.find("form").trigger("submit");
  await flushPromises();
};

describe("HomeSearch", () => {
  beforeEach(() => {
    // jsdom does not lay anything out, so it has no scrollIntoView.
    Element.prototype.scrollIntoView = vi.fn();
    vi.useFakeTimers();
    vi.mocked(search).mockClear();
    groups = [
      {
        type: "Location",
        items: [
          {
            type: "Location",
            name: "Port Tressler",
            slug: "port-tressler",
            detail: "microTech",
          },
        ],
      },
      {
        type: "Component",
        items: [
          {
            type: "Component",
            name: "GVSR Repeater",
            slug: "gvsr-s2",
            detail: "S2 · Behring",
          },
        ],
      },
    ];
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("groups the matches by catalogue, in the order the server ranked them", async () => {
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    await typeInto(wrapper, "port");

    const labels = wrapper.findAll(".home-search__group-label");
    expect(labels.map((label) => label.text())).toEqual([
      "Locations",
      "Components",
    ]);
    expect(wrapper.text()).toContain("S2 · Behring");
  });

  it("shows an item's picture, and its catalogue's icon where it has none", async () => {
    groups[0].items[0].image = {
      name: "tressler.jpg",
      contentType: "image/jpeg",
      size: 1,
      url: "https://example.test/tressler.jpg",
      smallUrl: "https://example.test/tressler-small.webp",
    };
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    await typeInto(wrapper, "port");

    const rows = wrapper.findAll("[data-test='home-search-result']");
    expect(
      rows[0].find(".search-result-label__thumb img").attributes("src"),
    ).toBe("https://example.test/tressler-small.webp");
    // Without a picture the icon takes a glyph's room, not a picture's.
    expect(rows[1].find(".search-result-label__thumb").exists()).toBe(false);
    expect(rows[1].find("[data-test='search-result-icon']").exists()).toBe(
      true,
    );
  });

  it("draws a planet and a system rather than picturing them", async () => {
    groups = [
      {
        type: "Location",
        items: [
          {
            type: "Location",
            name: "microTech",
            slug: "microtech",
            appearance: { kind: "planet", color: "#8fb8d0", flare: false },
          },
          {
            type: "Location",
            name: "Stanton System",
            slug: "stanton-system",
            appearance: { kind: "system", color: "#ffe08a", flare: false },
          },
          {
            type: "Location",
            name: "Port Tressler",
            slug: "port-tressler",
            appearance: { kind: "station", flare: false },
          },
        ],
      },
    ];
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    await typeInto(wrapper, "ton");

    const rows = wrapper.findAll("[data-test='home-search-result']");
    expect(rows[0].find("[data-test='location-globe']").exists()).toBe(true);
    expect(rows[1].find(".search-result-label__sun").exists()).toBe(true);
    expect(rows[2].find("[data-test='search-result-icon']").exists()).toBe(
      true,
    );
  });

  it("marks the text that matched in a name", async () => {
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    await typeInto(wrapper, "tress");

    expect(wrapper.find("mark").text()).toBe("Tress");
  });

  it("does not search for a single letter", async () => {
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    await typeInto(wrapper, "p");

    expect(search).not.toHaveBeenCalled();
    expect(wrapper.find("[data-test='home-search-results']").exists()).toBe(
      false,
    );
  });

  it("opens the highlighted match on Enter, the best one to start with", async () => {
    const instance = await router();
    const wrapper = await mountWithDefaults(Component, {
      plugins: [instance],
    });

    await typeInto(wrapper, "port");

    expect(wrapper.find(".home-search__option--active").text()).toContain(
      "Port Tressler",
    );

    await submit(wrapper);

    expect(instance.currentRoute.value.fullPath).toBe(
      "/locations/port-tressler",
    );
  });

  it("opens the match stepped to with the arrow keys", async () => {
    const instance = await router();
    const wrapper = await mountWithDefaults(Component, {
      plugins: [instance],
    });

    await typeInto(wrapper, "gvsr");
    await press(wrapper, "ArrowDown");
    await submit(wrapper);

    expect(instance.currentRoute.value.fullPath).toBe("/components/gvsr-s2");
  });

  it("stays put on Enter when nothing matches, and says so", async () => {
    groups = [];
    const instance = await router();
    const wrapper = await mountWithDefaults(Component, {
      plugins: [instance],
    });

    await typeInto(wrapper, "zzz");
    await submit(wrapper);

    expect(instance.currentRoute.value.name).toBe("home");
    expect(wrapper.find("[data-test='home-search-empty']").exists()).toBe(true);
  });

  // Enter pressed while the debounced search is still waiting to run.
  it("shows the matches rather than opening one on an Enter faster than the list", async () => {
    const instance = await router();
    const wrapper = await mountWithDefaults(Component, {
      plugins: [instance],
    });

    await wrapper.find("input").setValue("tressler");
    await submit(wrapper);

    expect(search).toHaveBeenCalledWith({ q: "tressler" });
    expect(instance.currentRoute.value.name).toBe("home");
    expect(wrapper.findAll("[data-test='home-search-result']")).toHaveLength(2);
  });

  it("searches a suggestion when it is clicked, without leaving the page", async () => {
    const instance = await router();
    const wrapper = await mountWithDefaults(Component, {
      props: { suggestions: ["Port Tressler", "GVSR"] },
      plugins: [instance],
    });

    const buttons = wrapper.findAll("[data-test='home-search-suggestion']");
    expect(buttons.map((button) => button.text())).toEqual([
      "Port Tressler",
      "GVSR",
    ]);

    await buttons[0].trigger("click");
    await flushPromises();

    expect(search).toHaveBeenCalledWith({ q: "Port Tressler" });
    expect((wrapper.find("input").element as HTMLInputElement).value).toBe(
      "Port Tressler",
    );
    expect(wrapper.findAll("[data-test='home-search-result']")).toHaveLength(2);
    expect(instance.currentRoute.value.name).toBe("home");
  });

  it("offers no suggestions row without suggestions", async () => {
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    expect(wrapper.find("[data-test='home-search-suggestions']").exists()).toBe(
      false,
    );
  });

  it("closes the list on Escape", async () => {
    const wrapper = await mountWithDefaults(Component, {
      plugins: [await router()],
    });

    await typeInto(wrapper, "port");
    await press(wrapper, "Escape");

    expect(wrapper.find("[data-test='home-search-results']").exists()).toBe(
      false,
    );
  });
});
