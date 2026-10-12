import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

describe("ModelSectionEmpty", () => {
  it("says which ship has nothing in which section", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        modelName: "Constellation Mk IV Andromeda",
        section: "Modules",
      },
    });

    expect(wrapper.text()).toBe(
      "The Constellation Mk IV Andromeda does not have any Modules.",
    );
  });
});
