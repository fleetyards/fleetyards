import { describe, expect, it } from "vitest";
import { nextTick, ref } from "vue";

import { useBulkSelection } from "./useBulkSelection";

type Row = { id: string };

const rows = (...ids: string[]): Row[] => ids.map((id) => ({ id }));

const setup = (
  ids: string[] = ["a", "b", "c"],
  query: Record<string, unknown> = { archivedAtNull: true },
  total: number | undefined = 3,
) => {
  const records = ref<Row[]>(rows(...ids));
  const filter = ref(query);
  const totalCount = ref<number | undefined>(total);

  return {
    records,
    filter,
    totalCount,
    selection: useBulkSelection(records, filter, totalCount),
  };
};

describe("useBulkSelection", () => {
  it("ticks and unticks a single row", () => {
    const { selection } = setup();

    selection.toggle("a");

    expect(selection.selectedIds.value).toEqual(["a"]);
    expect(selection.selectedCount.value).toBe(1);
    expect(selection.pagePartiallySelected.value).toBe(true);

    selection.toggle("a");

    expect(selection.selectedIds.value).toEqual([]);
    expect(selection.pagePartiallySelected.value).toBe(false);
  });

  it("reports the page as selected once every row is ticked", () => {
    const { selection } = setup();

    selection.togglePage(true);

    expect(selection.pageSelected.value).toBe(true);
    expect(selection.selectedCount.value).toBe(3);

    selection.togglePage(false);

    expect(selection.pageSelected.value).toBe(false);
  });

  it("offers select all matching only when the filter reaches past the page", () => {
    const { selection } = setup(["a", "b", "c"], {}, 3);

    selection.togglePage(true);

    expect(selection.canSelectAllMatching.value).toBe(false);

    const wider = setup(["a", "b", "c"], {}, 30);

    wider.selection.togglePage(true);

    expect(wider.selection.canSelectAllMatching.value).toBe(true);
  });

  it("counts every match once all matching is selected", () => {
    const { selection } = setup(["a", "b", "c"], {}, 30);

    selection.selectAllMatching();

    expect(selection.selectedCount.value).toBe(30);
    expect(selection.pageSelected.value).toBe(true);
    expect(selection.payload.value).toEqual({ all: true, q: {} });
  });

  it("falls back to the visible page when a row is unticked from all matching", () => {
    const { selection } = setup(["a", "b", "c"], {}, 30);

    selection.selectAllMatching();
    selection.toggle("b");

    expect(selection.allMatchingSelected.value).toBe(false);
    expect(selection.selectedIds.value).toEqual(["a", "c"]);
    expect(selection.payload.value).toEqual({ ids: ["a", "c"] });
  });

  it("drops ticks for rows that left the page", async () => {
    const { records, selection } = setup();

    selection.togglePage(true);

    records.value = rows("c", "d");
    await nextTick();

    expect(selection.selectedIds.value).toEqual(["c"]);
  });

  // Turning the page hands the composable a new query object holding the same
  // filter, which must not read as a filter change.
  it("keeps all matching across an unchanged filter", async () => {
    const { filter, selection } = setup(["a", "b", "c"], { sorts: [] }, 30);

    selection.selectAllMatching();

    filter.value = { sorts: [] };
    await nextTick();

    expect(selection.allMatchingSelected.value).toBe(true);
  });

  it("revokes all matching when the filter changes", async () => {
    const { filter, selection } = setup(["a", "b", "c"], { sorts: [] }, 30);

    selection.selectAllMatching();

    filter.value = { sorts: [], searchCont: "aurora" };
    await nextTick();

    expect(selection.allMatchingSelected.value).toBe(false);
  });
});
