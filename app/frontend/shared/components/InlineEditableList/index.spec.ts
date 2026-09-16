import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

// The mobile branch hides the row's buttons behind a dropdown, which is
// teleported out of the wrapper and leaves nothing to click.
vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => false,
}));

type Item = { id: string; name?: string };

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

const mount = (
  props: {
    items: Item[];
    loading?: boolean;
    skeletonRows?: number;
  },
  slots: Record<string, string> = {},
) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props,
    slots: { display: "<span>dock</span>", ...slots },
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

  describe("the headline of an open row", () => {
    // The fields replace the row's display, so without it there is nothing on
    // screen saying which record they belong to.
    it("names the record from its own name", async () => {
      const wrapper = await mount({
        items: [{ id: "dock-1", name: "Forward Bay" }],
      });

      await wrapper.find('[data-test="start-edit"]').trigger("click");

      expect(wrapper.find('[data-test="edit-headline"]').text()).toBe(
        "Forward Bay",
      );
    });

    it("is closed again with the row", async () => {
      const wrapper = await mount({
        items: [{ id: "dock-1", name: "Forward Bay" }],
      });

      expect(wrapper.find('[data-test="edit-headline"]').exists()).toBe(false);
    });

    it("takes the slot over the item's own name", async () => {
      const wrapper = await mount(
        { items: [{ id: "dock-1", name: "Forward Bay" }] },
        { headline: "<span>Hold #2</span>" },
      );

      await wrapper.find('[data-test="start-edit"]').trigger("click");

      expect(wrapper.find('[data-test="edit-headline"]').text()).toBe(
        "Hold #2",
      );
    });

    // A headline slot draws nothing for a record whose relation is gone - a
    // loaner without its model - and an empty line still holds a gap open.
    it("stays away where the slot draws nothing", async () => {
      const wrapper = await mount(
        { items: [{ id: "dock-1", name: "Forward Bay" }] },
        { headline: '<span v-if="false">gone</span> ' },
      );

      await wrapper.find('[data-test="start-edit"]').trigger("click");

      expect(wrapper.find('[data-test="edit-headline"]').exists()).toBe(false);
    });

    // A record naming itself nothing readable gets no empty line above the
    // fields - a list of those passes a headline slot instead.
    it("stays away where the record has no name", async () => {
      const wrapper = await mount({ items: [{ id: "dock-1" }] });

      await wrapper.find('[data-test="start-edit"]').trigger("click");

      expect(wrapper.find('[data-test="edit-headline"]').exists()).toBe(false);
    });
  });
});
