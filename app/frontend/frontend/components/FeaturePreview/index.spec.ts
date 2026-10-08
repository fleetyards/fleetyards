import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import FeaturePreview from "./index.vue";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const BtnStub = defineComponent({
  name: "Btn",
  emits: ["click"],
  setup(_, { slots, emit, attrs }) {
    return () =>
      h(
        "button",
        { ...attrs, type: "button", onClick: () => emit("click") },
        slots.default?.(),
      );
  },
});

const HeadingStub = defineComponent({
  name: "Heading",
  setup(_, { slots }) {
    return () => h("h1", [slots.default?.(), slots.subHeading?.()]);
  },
});

const mountPreview = () =>
  mount(FeaturePreview, {
    props: {
      title: "Your Hangar",
      lead: "Track every ship",
      backRoute: { name: "hangar" },
      features: [
        { id: "sync", icon: "fa-duotone fa-rotate", title: "Sync", text: "A" },
        {
          id: "stats",
          icon: "fa-duotone fa-chart-pie",
          title: "Stats",
          text: "B",
        },
      ],
    },
    global: { stubs: { Btn: BtnStub, Heading: HeadingStub } },
  });

beforeEach(() => {
  setActivePinia(createPinia());
});

describe("FeaturePreview", () => {
  it("lists every feature under the heading", () => {
    const wrapper = mountPreview();

    expect(wrapper.find("h1").text()).toContain("Your Hangar");
    expect(wrapper.find("h1").text()).toContain("Track every ship");
    expect(wrapper.find("[data-test='feature-sync']").text()).toContain("Sync");
    expect(wrapper.find("[data-test='feature-stats'] i").classes()).toContain(
      "fa-chart-pie",
    );
  });

  it("sends a new account back to the feature after signing up", async () => {
    const wrapper = mountPreview();

    await wrapper.find("[data-test='signup']").trigger("click");

    expect(useRedirectBackStore().backRoute).toEqual({ name: "hangar" });
    expect(wrapper.emitted("login")).toBeUndefined();
  });

  it("announces a login and sends it back to the feature", async () => {
    const wrapper = mountPreview();

    await wrapper.find("[data-test='login']").trigger("click");

    expect(useRedirectBackStore().backRoute).toEqual({ name: "hangar" });
    expect(wrapper.emitted("login")).toHaveLength(1);
  });
});
