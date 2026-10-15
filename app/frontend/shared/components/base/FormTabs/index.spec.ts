import { flushPromises, mount } from "@vue/test-utils";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import { createRouter, createMemoryHistory } from "vue-router";
import { createPinia } from "pinia";
import { Form } from "vee-validate";
import Component from "./index.vue";
import FormTab from "./Tab/index.vue";
import Tooltip from "@/shared/plugins/Tooltip";

const buildRouter = () =>
  createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/", component: { template: "<div />" } }],
  });

const mountInForm = async (slotContent: () => unknown) => {
  const router = buildRouter();
  await router.push("/");
  await router.isReady();

  const pinia = createPinia();

  return mount(
    defineComponent({
      components: { Form },
      setup: () => () =>
        h(Form, null, {
          default: slotContent,
        }),
    }),
    {
      global: {
        plugins: [router, pinia, Tooltip],
      },
      attachTo: document.body,
    },
  );
};

const setViewport = (phone: boolean) => {
  window.matchMedia = ((query: string) => ({
    matches: phone,
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

beforeAll(() => {
  Element.prototype.scrollTo = vi.fn();
});

beforeEach(() => {
  setViewport(false);
});

describe("FormTabs", () => {
  it("renders", async () => {
    const wrapper = await mountInForm(() =>
      h(
        Component,
        { syncUrl: false },
        {
          default: () => [
            h(FormTab, { id: "one", label: "One" }, () => "First"),
            h(FormTab, { id: "two", label: "Two" }, () => "Second"),
          ],
        },
      ),
    );

    expect(wrapper.exists()).toBe(true);
    expect(wrapper.findAll('[role="tab"]').length).toBe(2);
  });

  it("activates the first tab by default", async () => {
    const wrapper = await mountInForm(() =>
      h(
        Component,
        { syncUrl: false },
        {
          default: () => [
            h(FormTab, { id: "one", label: "One" }, () => "First"),
            h(FormTab, { id: "two", label: "Two" }, () => "Second"),
          ],
        },
      ),
    );

    const tabs = wrapper.findAll('[role="tab"]');
    expect(tabs[0].attributes("aria-selected")).toBe("true");
    expect(tabs[1].attributes("aria-selected")).toBe("false");
  });

  it("settles when fields arrive as a fresh array on every render", async () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const renders = vi.fn();

    await mountInForm(() =>
      h(
        Component,
        { syncUrl: false },
        {
          default: () => {
            renders();
            return [
              h(FormTab, { id: "one", label: "One", fields: ["a"] }, () => ""),
              h(FormTab, { id: "two", label: "Two", fields: ["b"] }, () => ""),
            ];
          },
        },
      ),
    );
    await flushPromises();

    expect(renders.mock.calls.length).toBeLessThan(5);
    expect(
      warn.mock.calls.some((args) =>
        String(args[0]).includes("Maximum recursive updates"),
      ),
    ).toBe(false);

    warn.mockRestore();
  });

  it("switches active tab on click", async () => {
    const wrapper = await mountInForm(() =>
      h(
        Component,
        { syncUrl: false },
        {
          default: () => [
            h(FormTab, { id: "one", label: "One" }, () => "First"),
            h(FormTab, { id: "two", label: "Two" }, () => "Second"),
          ],
        },
      ),
    );

    const tabs = wrapper.findAll('[role="tab"]');
    await tabs[1].trigger("click");
    expect(tabs[0].attributes("aria-selected")).toBe("false");
    expect(tabs[1].attributes("aria-selected")).toBe("true");
  });

  it("respects defaultTab prop", async () => {
    const wrapper = await mountInForm(() =>
      h(
        Component,
        { syncUrl: false, defaultTab: "two" },
        {
          default: () => [
            h(FormTab, { id: "one", label: "One" }, () => "First"),
            h(FormTab, { id: "two", label: "Two" }, () => "Second"),
          ],
        },
      ),
    );

    const tabs = wrapper.findAll('[role="tab"]');
    expect(tabs[1].attributes("aria-selected")).toBe("true");
  });

  it("skips disabled tab on activation", async () => {
    const wrapper = await mountInForm(() =>
      h(
        Component,
        { syncUrl: false },
        {
          default: () => [
            h(FormTab, { id: "one", label: "One" }, () => "First"),
            h(
              FormTab,
              { id: "two", label: "Two", disabled: true },
              () => "Second",
            ),
          ],
        },
      ),
    );

    const tabs = wrapper.findAll('[role="tab"]');
    await tabs[1].trigger("click");
    expect(tabs[0].attributes("aria-selected")).toBe("true");
    expect(tabs[1].attributes("aria-selected")).toBe("false");
  });

  it("shows only the active icon tab's label and keeps names accessible", async () => {
    const wrapper = await mountInForm(() =>
      h(
        Component,
        { syncUrl: false, horizontal: true, activeLabelOnly: true },
        {
          default: () => [
            h(
              FormTab,
              { id: "one", label: "One", icon: "fa-solid fa-eye" },
              () => "First",
            ),
            h(
              FormTab,
              { id: "two", label: "Two", iconSrc: "/radar.svg" },
              () => "Second",
            ),
          ],
        },
      ),
    );
    const tabs = wrapper.findAll('[role="tab"]');

    expect(tabs[0].text()).toBe("One");
    expect(tabs[1].find(".tab-anchor__label").attributes("aria-hidden")).toBe(
      "true",
    );
    expect(tabs[1].attributes("aria-label")).toBe("Two");
    expect(tabs[1].find("img").attributes("src")).toBe("/radar.svg");
    expect(tabs[1].classes()).toContain("tab-anchor--compact");
    await tabs[1].trigger("mouseenter");
    expect(document.body.querySelector("[data-tooltip]")?.textContent).toBe(
      "Two",
    );
    await tabs[1].trigger("keydown", { key: "Enter" });
    expect(tabs[0].find(".tab-anchor__label").attributes("aria-hidden")).toBe(
      "true",
    );
    expect(tabs[1].text()).toBe("Two");

    wrapper.unmount();
  });

  it("keeps disabled tab hints and labels for tabs without icons", async () => {
    const wrapper = await mountInForm(() =>
      h(
        Component,
        { syncUrl: false, horizontal: true, activeLabelOnly: true },
        {
          default: () => [
            h(
              FormTab,
              { id: "one", label: "One", icon: "fa-solid fa-eye" },
              () => "First",
            ),
            h(
              FormTab,
              {
                id: "two",
                label: "Two",
                icon: "fa-solid fa-camera",
                disabled: true,
                hint: "Coming soon",
              },
              () => "Second",
            ),
            h(FormTab, { id: "three", label: "Three" }, () => "Third"),
          ],
        },
      ),
    );
    const tabs = wrapper.findAll('[role="tab"]');

    expect(tabs[1].find(".tab-anchor__label").attributes("aria-hidden")).toBe(
      "true",
    );
    await tabs[1].trigger("mouseenter");
    expect(document.body.querySelector("[data-tooltip]")?.textContent).toBe(
      "Two — Coming soon",
    );
    await tabs[1].trigger("click");
    expect(tabs[0].attributes("aria-selected")).toBe("true");
    expect(tabs[2].text()).toBe("Three");

    wrapper.unmount();
  });

  describe("on a phone", () => {
    beforeEach(() => {
      setViewport(true);
    });

    const mountTabs = () =>
      mountInForm(() =>
        h(
          Component,
          { syncUrl: false, horizontal: true, activeLabelOnly: true },
          {
            default: () => [
              h(
                FormTab,
                { id: "one", label: "One", icon: "fa-solid fa-eye" },
                () => "First",
              ),
              h(
                FormTab,
                { id: "two", label: "Two", icon: "fa-solid fa-camera" },
                () => "Second",
              ),
              h(
                FormTab,
                { id: "three", label: "Three", disabled: true },
                () => "Third",
              ),
            ],
          },
        ),
      );

    it("folds the tabs into the dropdown", async () => {
      const wrapper = await mountTabs();

      expect(wrapper.findAll('[role="tab"]')).toHaveLength(0);
      expect(wrapper.find(".tab-nav-dropdown__label").text()).toBe("One");
    });

    it("switches tab from the dropdown", async () => {
      const wrapper = await mountTabs();

      await wrapper.find(".tab-nav-dropdown__trigger").trigger("click");
      await wrapper
        .find('[data-test="tab-anchor-option-two"]')
        .trigger("click");

      expect(wrapper.find(".tab-nav-dropdown__label").text()).toBe("Two");
      expect(wrapper.find('[role="listbox"]').exists()).toBe(false);
    });

    it("ignores a disabled tab in the dropdown", async () => {
      const wrapper = await mountTabs();

      await wrapper.find(".tab-nav-dropdown__trigger").trigger("click");
      await wrapper
        .find('[data-test="tab-anchor-option-three"]')
        .trigger("click");

      expect(wrapper.find(".tab-nav-dropdown__label").text()).toBe("One");
    });
  });
});
