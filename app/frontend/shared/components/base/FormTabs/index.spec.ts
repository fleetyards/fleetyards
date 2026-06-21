import { mount } from "@vue/test-utils";
import { beforeAll, describe, expect, it, vi } from "vitest";
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

beforeAll(() => {
  Element.prototype.scrollTo = vi.fn();
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
});
