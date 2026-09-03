import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { nextTick } from "vue";
import { MINIMUM_WAIT_MS } from "@/shared/composables/useMinimumDuration";
import Component from "./index.vue";

type Item = { id: string };

// ListGroup is a generic SFC, which is not a plain constructor type; this names
// the props and slots the tests use without reaching for `any`.
const ListComponent = Component as unknown as new (...args: unknown[]) => {
  $props: {
    items: Item[];
    loading?: boolean;
    skeletonRows?: number;
  };
  $slots: Record<string, unknown>;
};

const mount = (
  props: { items: Item[]; loading?: boolean; skeletonRows?: number },
  slots?: Record<string, string>,
) => mountWithDefaults<typeof ListComponent>(ListComponent, { props, slots });

const skeletonRows = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll('[data-test="list-group-skeleton-row"]');

afterEach(() => {
  vi.useRealTimers();
});

describe("ListGroup", () => {
  it("holds the list open with placeholder rows on the first load", async () => {
    const wrapper = await mount({
      items: [],
      loading: true,
      skeletonRows: 4,
    });

    expect(skeletonRows(wrapper)).toHaveLength(4);
  });

  // A refetch keeps the records it already has on screen, and they hold the
  // list open better than placeholders would.
  it("leaves the records in place while they are refetched", async () => {
    const wrapper = await mount({
      items: [{ id: "dock-1" }],
      loading: true,
      skeletonRows: 4,
    });

    expect(skeletonRows(wrapper)).toHaveLength(0);
    expect(wrapper.findAll('[data-test="list-group-item"]')).toHaveLength(1);
  });

  // These lists are short and carry no page size to read a bound off, so a
  // full page of placeholders would claim a screenful of nothing.
  it("reserves a short list where nothing is known yet", async () => {
    const wrapper = await mount({ items: [], loading: true });

    expect(skeletonRows(wrapper)).toHaveLength(3);
  });

  // A count of zero is an answer rather than a missing one: a list known to be
  // empty should reserve nothing.
  it("reserves nothing for a list known to be empty", async () => {
    const wrapper = await mount({ items: [], loading: true, skeletonRows: 0 });

    expect(skeletonRows(wrapper)).toHaveLength(0);
  });

  // The actions area of a row holds buttons, and those set the row's height
  // rather than the text beside them - so the placeholder reserves a block of
  // the control's own size there. A list whose rows carry no buttons gets none,
  // or it would stand half a control taller than the rows it waits for.
  it("reserves a control for a list that carries actions", async () => {
    const withActions = await mount(
      { items: [], loading: true },
      {
        actions: "<button>edit</button>",
      },
    );

    const row = withActions.get('[data-test="list-group-skeleton-row"]');

    expect(
      row.find(".list-group__actions .skeleton-bar--control").exists(),
    ).toBe(true);

    const plain = await mount({ items: [], loading: true });
    const plainRow = plain.get('[data-test="list-group-skeleton-row"]');

    expect(plainRow.find(".skeleton-bar--control").exists()).toBe(false);
  });

  it("keeps the placeholders out of the reading order", async () => {
    const wrapper = await mount({ items: [], loading: true });

    expect(
      wrapper
        .get('[data-test="list-group-skeleton-row"]')
        .attributes("aria-hidden"),
    ).toBe("true");
  });

  // The empty box is what the answer turned out to be, and putting it up under
  // the placeholders would say the list is empty while it is still loading.
  it("holds the empty state back while it waits", async () => {
    const wrapper = await mount({ items: [], loading: true });

    expect(wrapper.find(".empty-list").exists()).toBe(false);
  });

  // A list on its own is handed a query's own flag, and a cached page answers
  // inside a frame or two - placeholders that come and go that fast read as a
  // glitch rather than as a load.
  it("holds the placeholders up long enough to read", async () => {
    const wrapper = await mount({ items: [], loading: true, skeletonRows: 2 });

    vi.useFakeTimers();

    await wrapper.setProps({ loading: false });

    expect(skeletonRows(wrapper)).toHaveLength(2);
    expect(wrapper.find(".empty-list").exists()).toBe(false);

    vi.advanceTimersByTime(MINIMUM_WAIT_MS + 100);
    await nextTick();

    expect(skeletonRows(wrapper)).toHaveLength(0);
    expect(wrapper.find(".empty-list").exists()).toBe(true);
  });

  it("keeps the spinner while nothing else is showing one", async () => {
    const wrapper = await mount({ items: [], loading: true });

    expect(wrapper.findComponent({ name: "LoaderComponent" }).props()).toEqual(
      expect.objectContaining({ loading: true }),
    );
  });
});
