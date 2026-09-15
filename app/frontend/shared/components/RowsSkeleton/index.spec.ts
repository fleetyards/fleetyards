import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const mount = (
  props: {
    count?: number;
    icon?: boolean;
    trailing?: boolean;
    meta?: boolean;
  } = {},
) => mountWithDefaults<typeof Component>(Component, { props });

describe("RowsSkeleton", () => {
  it("reserves the rows the panel is waiting for", async () => {
    const wrapper = await mount({ count: 4 });

    expect(wrapper.findAll(".rows-skeleton__row")).toHaveLength(4);
  });

  // The rows these stand in for differ per list - an entry carries an icon and
  // an amount, a participant carries neither - and a placeholder with parts the
  // record has not got shifts the row as it lands.
  it("carries only the parts the rows it stands in for have", async () => {
    const bare = await mount({ count: 1, meta: false });

    expect(bare.find(".rows-skeleton__icon").exists()).toBe(false);
    expect(bare.find(".skeleton-bar--trailing").exists()).toBe(false);
    expect(bare.find(".skeleton-bar--meta").exists()).toBe(false);

    const full = await mount({ count: 1, icon: true, trailing: true });

    expect(full.find(".rows-skeleton__icon").exists()).toBe(true);
    expect(full.find(".skeleton-bar--trailing").exists()).toBe(true);
    expect(full.find(".skeleton-bar--meta").exists()).toBe(true);
  });

  it("keeps the placeholders out of the reading order", async () => {
    const wrapper = await mount();

    expect(
      wrapper.get('[data-test="rows-skeleton"]').attributes("aria-hidden"),
    ).toBe("true");
  });
});
