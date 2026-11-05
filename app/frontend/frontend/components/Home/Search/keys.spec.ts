import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type SearchGroup } from "@/services/fyApi";

const groups: SearchGroup[] = [
  {
    type: "Commodity",
    hasMore: false,
    items: [{ type: "Commodity", name: "Ore", slug: "ore" }],
  },
  {
    type: "Location",
    hasMore: false,
    items: [{ type: "Location", name: "Orison", slug: "orison" }],
  },
];

const catalogue = vi.fn(async () => ({ groups }));
const mine = vi.fn(async () => ({ groups: [] }));
const add = vi.fn();
const stored = { scope: "catalogue" };

vi.mock("@/frontend/stores/search", () => ({
  useSearchStore: () => stored,
}));

vi.mock("@/frontend/components/Home/Search/useSearchScopes", async () => {
  const { ref, computed } = await import("vue");
  const selected = ref("catalogue");
  const scopes = computed(() => [
    {
      key: "catalogue",
      labelKey: "nav.catalogue.index",
      icon: "fa-books",
      search: catalogue,
    },
    {
      key: "mine",
      labelKey: "nav.hangar.index",
      icon: "fa-warehouse",
      search: mine,
    },
  ]);
  const current = computed(() =>
    scopes.value.find((scope) => scope.key === selected.value)!,
  );

  return {
    CATALOGUE_SCOPE: "catalogue",
    useSearchScopes: () => ({
      scopes,
      current,
      select: (key: string) => {
        selected.value = key;
      },
      step: (by: number) => {
        const index = scopes.value.indexOf(current.value);
        selected.value = scopes.value[(index + by + 2) % 2].key;
      },
    }),
  };
});

vi.mock("@/frontend/components/Home/Search/useSearchResultAdd", () => ({
  HANGAR_TYPES: ["Model", "Blueprint"],
  useSearchResultAdd: () => ({
    canAdd: (result: { type: string }) => result.type === "Commodity",
    add,
  }),
}));

vi.mock("@/shared/composables/useLowPowerDevice", async () => {
  const { ref } = await import("vue");

  return { useLowPowerDevice: () => ref(false) };
});

const Component = (await import("./index.vue")).default;

const mount = async () => {
  const blank = { template: "<div />" };
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: blank },
      { path: "/other", name: "other", component: blank },
      { path: "/commodities/:slug", name: "commodity", component: blank },
    ],
  });
  await router.push({ name: "home" });
  await router.isReady();

  const wrapper = await mountWithDefaults(Component, { plugins: [router] });

  await wrapper.find("input").setValue("or");
  await vi.advanceTimersByTimeAsync(300);
  await flushPromises();

  return { router, wrapper };
};

describe("HomeSearch shortcut", () => {
  const press = (target: EventTarget, init: KeyboardEventInit) => {
    const event = new KeyboardEvent("keydown", {
      bubbles: true,
      cancelable: true,
      ...init,
    });

    target.dispatchEvent(event);

    return event;
  };

  const mountAttached = async () => {
    const router = createRouter({
      history: createWebHashHistory(),
      routes: [{ path: "/", name: "home", component: { template: "<div />" } }],
    });

    return mountWithDefaults(Component, {
      plugins: [router],
      attachTo: document.body,
    });
  };

  afterEach(() => {
    document.body.innerHTML = "";
  });

  it("takes the focus on the slash key", async () => {
    const wrapper = await mountAttached();

    const event = press(document.body, { key: "/" });

    expect(event.defaultPrevented).toBe(true);
    expect(document.activeElement).toBe(wrapper.find("input").element);

    wrapper.unmount();
  });

  // jsdom reports no platform, so this runs as a machine with a Ctrl key.
  it("takes the focus on Ctrl+K, from inside another field too", async () => {
    const wrapper = await mountAttached();
    const other = document.body.appendChild(document.createElement("input"));

    other.focus();
    press(other, { key: "k", ctrlKey: true });

    expect(document.activeElement).toBe(wrapper.find("input").element);

    wrapper.unmount();
  });

  it.each([
    ["input", () => document.createElement("input")],
    ["textarea", () => document.createElement("textarea")],
    [
      "editor",
      () => {
        const editor = document.createElement("div");
        editor.setAttribute("contenteditable", "true");
        return editor;
      },
    ],
    [
      "select",
      () => {
        const select = document.createElement("button");
        select.setAttribute("role", "combobox");
        return select;
      },
    ],
  ])("leaves the slash key to a %s", async (_name, build) => {
    const wrapper = await mountAttached();
    const field = document.body.appendChild(build());

    const event = press(field, { key: "/" });

    expect(event.defaultPrevented).toBe(false);
    expect(document.activeElement).not.toBe(wrapper.find("input").element);

    wrapper.unmount();
  });

  it("leaves Ctrl+K to the markdown editor", async () => {
    const wrapper = await mountAttached();
    const editor = document.body.appendChild(document.createElement("div"));
    editor.setAttribute("contenteditable", "true");

    expect(press(editor, { key: "k", ctrlKey: true }).defaultPrevented).toBe(
      false,
    );

    wrapper.unmount();
  });

  it("does nothing behind a modal", async () => {
    const wrapper = await mountAttached();
    const modal = document.body.appendChild(document.createElement("div"));
    modal.setAttribute("aria-modal", "true");

    expect(press(document.body, { key: "/" }).defaultPrevented).toBe(false);
    expect(document.activeElement).not.toBe(wrapper.find("input").element);

    wrapper.unmount();
  });

  it("stops listening once it is gone", async () => {
    const wrapper = await mountAttached();

    wrapper.unmount();

    expect(press(document.body, { key: "/" }).defaultPrevented).toBe(false);
  });
});

describe("HomeSearch keys", () => {
  beforeEach(() => {
    Element.prototype.scrollIntoView = vi.fn();
    vi.useFakeTimers();
    catalogue.mockClear();
    mine.mockReset();
    mine.mockImplementation(async () => ({ groups: [] }));
    add.mockReset();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("switches scope with tab from the field and searches it straight away", async () => {
    const { wrapper } = await mount();

    await wrapper.find("input").trigger("keydown", { key: "Tab" });
    await flushPromises();

    expect(mine).toHaveBeenCalledWith("or");
    expect(wrapper.find("input").element.value).toBe("or");

    await wrapper
      .find("input")
      .trigger("keydown", { key: "Tab", shiftKey: true });
    await flushPromises();

    expect(catalogue).toHaveBeenCalledTimes(2);
  });

  it("does not act on the previous scope's matches while the new one answers", async () => {
    mine.mockImplementation(() => new Promise<{ groups: never[] }>(() => {}));
    const { router, wrapper } = await mount();
    const input = wrapper.find("input");

    await input.trigger("keydown", { key: "Tab" });
    await flushPromises();

    expect(wrapper.find("[data-test='home-search-searching']").exists()).toBe(
      true,
    );
    expect(wrapper.find("[data-test='home-search-result']").exists()).toBe(
      false,
    );

    await input.trigger("keydown", { key: "Enter", metaKey: true });
    await flushPromises();

    expect(add).not.toHaveBeenCalled();
    expect(router.currentRoute.value.name).toBe("home");

    await input.trigger("keydown", { key: "Tab", shiftKey: true });
    await flushPromises();
  });

  it("offers the catalogue when nothing of a saved scope matches", async () => {
    const { wrapper } = await mount();

    await wrapper.find("input").trigger("keydown", { key: "Tab" });
    await flushPromises();
    expect(
      wrapper.find("[data-test='home-search-in-catalogue']").exists(),
    ).toBe(true);

    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find("[data-test='home-search-result']").exists()).toBe(
      true,
    );
  });

  it("leaves tab alone once the overlay is closed", async () => {
    const { wrapper } = await mount();

    await wrapper.find("input").trigger("keydown", { key: "Escape" });
    await wrapper.find("input").trigger("keydown", { key: "Tab" });
    await flushPromises();

    expect(mine).not.toHaveBeenCalled();
  });

  it("adds the highlighted row and closes the overlay", async () => {
    add.mockResolvedValue("opened");
    const { wrapper } = await mount();

    await wrapper
      .find("input")
      .trigger("keydown", { key: "Enter", metaKey: true });
    await flushPromises();

    expect(add).toHaveBeenCalledWith(expect.objectContaining({ slug: "ore" }));
    expect(wrapper.find("[data-test='home-search-results']").exists()).toBe(
      false,
    );
  });

  it("opens the item's page when it turns out it cannot be added", async () => {
    add.mockResolvedValue("unavailable");
    const { router, wrapper } = await mount();

    await wrapper
      .find("input")
      .trigger("keydown", { key: "Enter", ctrlKey: true });
    await flushPromises();

    expect(router.currentRoute.value.name).toBe("commodity");
  });

  it("does nothing on a row that cannot be added, and only offers the key where it can", async () => {
    const { wrapper } = await mount();

    expect(wrapper.find("[data-test='home-search-key-add']").exists()).toBe(
      true,
    );

    await wrapper.find("input").trigger("keydown", { key: "ArrowDown" });
    await flushPromises();

    expect(wrapper.find("[data-test='home-search-key-add']").exists()).toBe(
      false,
    );

    await wrapper
      .find("input")
      .trigger("keydown", { key: "Enter", ctrlKey: true });
    await flushPromises();

    expect(add).not.toHaveBeenCalled();
  });

  it("does not add a row held from older text while the new text waits", async () => {
    const { wrapper } = await mount();
    const input = wrapper.find("input");

    await input.setValue("ore");
    await input.trigger("keydown", { key: "Enter", metaKey: true });
    await flushPromises();

    expect(add).not.toHaveBeenCalled();
  });

  it("clears the field when the page changes", async () => {
    const { router, wrapper } = await mount();

    await router.push({ name: "other" });
    await flushPromises();

    expect(wrapper.find("input").element.value).toBe("");
  });

  it("drops an answer still on its way when the page changes", async () => {
    let answer: (results: { groups: SearchGroup[] }) => void = () => {};
    const { router, wrapper } = await mount();
    const input = wrapper.find("input");

    catalogue.mockImplementationOnce(
      () =>
        new Promise((resolve) => {
          answer = resolve;
        }),
    );
    await input.setValue("orb");
    await vi.advanceTimersByTimeAsync(300);

    await router.push({ name: "other" });
    await flushPromises();
    answer({ groups });
    await flushPromises();

    await input.setValue("orb");
    await flushPromises();

    expect(wrapper.find("[data-test='home-search-searching']").exists()).toBe(
      true,
    );
  });

  it("does not search for text cleared while the search waited", async () => {
    const { router, wrapper } = await mount();

    catalogue.mockClear();
    await wrapper.find("input").setValue("orb");
    await router.push({ name: "other" });
    await flushPromises();
    await vi.advanceTimersByTimeAsync(300);

    expect(catalogue).not.toHaveBeenCalled();
  });

  it("switches scope from a tab activated without a pointer", async () => {
    const { wrapper } = await mount();

    await wrapper
      .findAll("[data-test='home-search-scope']")[1]
      .trigger("click");
    await flushPromises();

    expect(mine).toHaveBeenCalledWith("or");

    await wrapper
      .findAll("[data-test='home-search-scope']")[0]
      .trigger("click");
    await flushPromises();
  });
});
