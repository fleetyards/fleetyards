import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type MediaFile } from "@/services/fyApi";
import Component from "./index.vue";

const image = {
  smallUrl: "https://example.test/small.webp",
  mediumUrl: "https://example.test/medium.webp",
} as MediaFile;

const src = async (variant?: "row" | "panel") => {
  const wrapper = await mountWithDefaults(Component, {
    props: { image, variant },
  });

  return wrapper.find('[data-test="blueprint-plan-image"]').attributes("src");
};

describe("Blueprints/Plan", () => {
  it("draws a row's plan from the small render", async () => {
    expect(await src()).toBe(image.smallUrl);
  });

  it("draws the panel from the medium render", async () => {
    expect(await src("panel")).toBe(image.mediumUrl);
  });
});
