import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type Sortable from "sortablejs";
import Component from "./index.vue";

// Captured so the drag can be played back: jsdom has no pointer, so the only
// way to reach onEnd is the options Sortable was created with.
let options: Sortable.Options | undefined;
const destroy = vi.fn();

vi.mock("sortablejs", () => ({
  default: {
    create: vi.fn((_el: HTMLElement, opts: Sortable.Options) => {
      options = opts;
      return { destroy };
    }),
  },
}));

type Squadron = { id: string };

const records: Squadron[] = [{ id: "a" }, { id: "b" }, { id: "c" }];

// The component is generic over its record type, and a generic SFC does not
// satisfy the constructor signature the mount helper is typed against -- so the
// cast goes in here once, and the two things this file actually reads off the
// wrapper are named rather than left as `never`.
type GridWrapper = {
  element: HTMLElement;
  emitted: (name: string) => unknown[][] | undefined;
};

const mountGrid = async (rows: Squadron[] = records, sortable = true) =>
  (await mountWithDefaults(
    Component as never,
    {
      props: {
        records: rows,
        primaryKey: "id",
        sortable,
        sortHandle: ".grip",
      },
      attachTo: document.body,
    } as never,
  )) as unknown as GridWrapper;

/*
 * The drag reports where a card came from and where it went. What the grid does
 * with that is the part worth pinning: the order it hands back, and the fact
 * that it does not leave the moved node where Sortable put it -- this list is a
 * transition-group, and two things writing the same children is what makes a
 * card jump.
 */
describe("BaseGrid", () => {
  beforeEach(() => {
    options = undefined;
    destroy.mockClear();
  });

  it("arms nothing when it is not sortable", async () => {
    await mountGrid(records, false);

    expect(options).toBeUndefined();
  });

  it("drags by the handle it was given", async () => {
    await mountGrid();

    expect(options?.handle).toBe(".grip");
  });

  it("reports the keys in the order they now sit in", async () => {
    const wrapper = await mountGrid();
    const cells = wrapper.element.querySelectorAll(".base-grid__cell");

    options?.onEnd?.({
      item: cells[0],
      oldIndex: 0,
      newIndex: 2,
    } as never);

    expect(wrapper.emitted("sort")?.[0]).toEqual([["b", "c", "a"]]);
  });

  it("reports a move back up the list", async () => {
    const wrapper = await mountGrid();
    const cells = wrapper.element.querySelectorAll(".base-grid__cell");

    options?.onEnd?.({
      item: cells[2],
      oldIndex: 2,
      newIndex: 0,
    } as never);

    expect(wrapper.emitted("sort")?.[0]).toEqual([["c", "a", "b"]]);
  });

  it("says nothing when the card came back where it started", async () => {
    const wrapper = await mountGrid();
    const cells = wrapper.element.querySelectorAll(".base-grid__cell");

    options?.onEnd?.({
      item: cells[1],
      oldIndex: 1,
      newIndex: 1,
    } as never);

    expect(wrapper.emitted("sort")).toBeUndefined();
  });

  // Sortable has already moved the node by the time onEnd runs. Left there, the
  // DOM and Vue disagree about where every card after it sits.
  it("puts the node back so the render owns the order", async () => {
    const wrapper = await mountGrid();
    // The transition-group renders the row itself, so the root is the container.
    const container = wrapper.element as HTMLElement;
    const cells = container.querySelectorAll(".base-grid__cell");
    const moved = cells[0];

    // What the drag did to the DOM before handing back to us.
    moved.remove();
    container.appendChild(moved);

    options?.onEnd?.({ item: moved, oldIndex: 0, newIndex: 2 } as never);

    expect(Array.from(container.children).indexOf(moved)).toBe(0);
  });
});
