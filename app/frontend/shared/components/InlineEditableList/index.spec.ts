import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

type Item = { id: string; name: string };

// InlineEditableList is a generic SFC, which is not a plain constructor type;
// this names the props and slots the tests use without reaching for `any`.
const ListComponent = Component as unknown as new (...args: unknown[]) => {
  $props: {
    items: Item[];
    loading?: boolean;
    skeletonRows?: number;
  };
  $slots: Record<string, unknown>;
};

const mount = (props: {
  items: Item[];
  loading?: boolean;
  skeletonRows?: number;
}) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props,
    slots: { display: "<span>dock</span>" },
  });

const skeletonRows = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll('[data-test="list-group-skeleton-row"]');

describe("InlineEditableList", () => {
  // Every row of an editable list carries the edit and destroy buttons, so its
  // placeholders stand as tall as those rather than as tall as a line of text.
  it("holds the list open with placeholder rows on the first load", async () => {
    const wrapper = await mount({ items: [], loading: true, skeletonRows: 4 });

    expect(skeletonRows(wrapper)).toHaveLength(4);
    expect(
      skeletonRows(wrapper)[0]
        .find(".list-group__actions .skeleton-bar--control")
        .exists(),
    ).toBe(true);
  });

  it("leaves the records in place while they are refetched", async () => {
    const wrapper = await mount({
      items: [{ id: "dock-1", name: "Forward Bay" }],
      loading: true,
      skeletonRows: 4,
    });

    expect(skeletonRows(wrapper)).toHaveLength(0);
    expect(wrapper.findAll('[data-test="list-group-item"]')).toHaveLength(1);
  });
});
