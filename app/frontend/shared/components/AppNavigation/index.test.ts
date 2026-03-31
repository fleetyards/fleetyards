import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import { setActivePinia, createPinia } from "pinia";

describe("AppNavigation", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("renders", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        title: "Test",
        logo: "logo.png",
      },
    });
    expect(wrapper.exists()).toBe(true);
  });

  it("renders nothing without pagination info", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        title: "Test",
        logo: "logo.png",
      },
    });
    expect(wrapper.findAll("nav")).toHaveLength(1);
  });
});
