import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type Sortable from "sortablejs";
import Component from "./index.vue";
import { type BaseTableCol } from "./types";

// Captured so the drag can be played back: jsdom has no pointer, so the only
// way to reach onEnd is the options Sortable was created with.
let options: Sortable.Options | undefined;
let container: HTMLElement | undefined;

vi.mock("sortablejs", () => ({
  default: {
    create: vi.fn((el: HTMLElement, opts: Sortable.Options) => {
      options = opts;
      container = el;
      return { destroy: vi.fn() };
    }),
  },
}));

type Row = { id: string };

const records: Row[] = [{ id: "a" }, { id: "b" }, { id: "c" }];

const columns: BaseTableCol<Row>[] = [{ name: "id", label: "Id" }];

type TableWrapper = {
  emitted: (name: string) => unknown[][] | undefined;
};

const mountTable = async (sortable = true) =>
  (await mountWithDefaults(
    Component as never,
    {
      props: {
        records,
        columns,
        primaryKey: "id",
        sortable,
        sortHandle: ".grip",
      },
      attachTo: document.body,
    } as never,
  )) as unknown as TableWrapper;

const rows = () =>
  Array.from(container?.querySelectorAll<HTMLElement>(".base-table-row") ?? []);

describe("BaseTable rows by drag", () => {
  beforeEach(() => {
    options = undefined;
    container = undefined;
  });

  it("arms nothing when it is not sortable", async () => {
    await mountTable(false);

    expect(options).toBeUndefined();
  });

  it("drags the body rows by the handle it was given", async () => {
    await mountTable();

    expect(options?.handle).toBe(".grip");
    expect(options?.draggable).toBe(".base-table-row");
  });

  it("reports the keys in the order they now sit in", async () => {
    const wrapper = await mountTable();

    options?.onEnd?.({ item: rows()[0], oldIndex: 0, newIndex: 2 } as never);

    expect(wrapper.emitted("sort")?.[0]).toEqual([["b", "c", "a"], "a"]);
  });

  it("says nothing when the row came back where it started", async () => {
    const wrapper = await mountTable();

    options?.onEnd?.({ item: rows()[1], oldIndex: 1, newIndex: 1 } as never);

    expect(wrapper.emitted("sort")).toBeUndefined();
  });

  it("puts the row back so the render owns the order", async () => {
    await mountTable();
    const moved = rows()[0];

    moved.remove();
    container?.appendChild(moved);

    options?.onEnd?.({ item: moved, oldIndex: 0, newIndex: 2 } as never);

    expect(rows().indexOf(moved)).toBe(0);
  });
});
