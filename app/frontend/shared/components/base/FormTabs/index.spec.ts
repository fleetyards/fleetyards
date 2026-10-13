import { mount } from "@vue/test-utils";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import { createRouter, createMemoryHistory } from "vue-router";
import { createPinia } from "pinia";
import { Form } from "vee-validate";
import Component from "./index.vue";
import FormTab from "./Tab/index.vue";

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
        plugins: [router, pinia],
      },
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

  describe("on a phone", () => {
    beforeEach(() => {
      setViewport(true);
    });

    const mountTabs = () =>
      mountInForm(() =>
        h(
          Component,
          { syncUrl: false },
          {
            default: () => [
              h(FormTab, { id: "one", label: "One" }, () => "First"),
              h(FormTab, { id: "two", label: "Two" }, () => "Second"),
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
