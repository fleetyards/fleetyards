import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { h } from "vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Component from "./index.vue";

describe("AppModalInner", () => {
  it("sizes the footer's buttons large and leaves the body's alone", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      slots: {
        default: () => [h(Btn, { "data-test": "body-btn" }, () => "Body")],
        footer: () => [h(Btn, { "data-test": "footer-btn" }, () => "Footer")],
      },
    });

    expect(wrapper.get("[data-test='footer-btn']").classes()).toContain(
      "btn--lg",
    );
    expect(wrapper.get("[data-test='body-btn']").classes()).toContain(
      "btn--sm",
    );
  });
});
