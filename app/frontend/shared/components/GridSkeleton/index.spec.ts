import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const mount = (props: { count: number; details?: boolean }) =>
  mountWithDefaults<typeof Component>(Component, { props });

describe("GridSkeleton", () => {
  it("renders one placeholder per record the page will hold", async () => {
    const wrapper = await mount({ count: 7 });

    expect(wrapper.findAll(".grid-skeleton__media")).toHaveLength(7);
  });

  // The cells are the real grid's, so the placeholders break onto rows exactly
  // where the cards will - a placeholder in a column of its own reserves the
  // wrong height however tall it is.
  it("lays the placeholders out in the grid's own cells", async () => {
    const wrapper = await mount({ count: 1 });

    expect(wrapper.get(".base-grid__cell").classes()).toEqual(
      expect.arrayContaining(["col-12", "col-md-6", "col-lg-4"]),
    );
  });

  it("stands in for the expanded card only when the list is expanded", async () => {
    const compact = await mount({ count: 1 });

    expect(compact.find(".grid-skeleton__metrics").exists()).toBe(false);

    const expanded = await mount({ count: 1, details: true });

    expect(expanded.find(".grid-skeleton__metrics").exists()).toBe(true);
    expect(expanded.findAll(".metrics-card__row")).toHaveLength(9);
  });

  it("keeps the placeholders out of the reading order", async () => {
    const wrapper = await mount({ count: 2 });

    expect(
      wrapper.get('[data-test="grid-skeleton"]').attributes("aria-hidden"),
    ).toBe("true");
  });
});
