import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import { type BaseTableCol } from "./types";

type Row = { slug: string; name: string };

const columns: BaseTableCol<Row>[] = [
  { name: "name", label: "Name", width: "200px" },
  { name: "focus", label: "Focus" },
];

// A generic SFC is not a plain constructor type; this names the props the tests
// use without reaching for `any`.
const TableComponent = Component as unknown as new (...args: unknown[]) => {
  $props: {
    records: Row[];
    columns: BaseTableCol<Row>[];
    primaryKey: keyof Row;
    loading?: boolean;
    skeletonRows?: number;
  };
};

const mount = (props: {
  records: Row[];
  loading?: boolean;
  skeletonRows?: number;
}) =>
  mountWithDefaults<typeof TableComponent>(TableComponent, {
    props: { columns, primaryKey: "slug", ...props },
  });

const skeletonRows = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll('[data-test="base-table-skeleton-row"]');

describe("BaseTable", () => {
  it("holds the table open with placeholder rows on the first load", async () => {
    const wrapper = await mount({
      records: [],
      loading: true,
      skeletonRows: 5,
    });

    expect(skeletonRows(wrapper)).toHaveLength(5);
  });

  // A refetch keeps what it has on screen, and the records hold the table open
  // better than placeholders would.
  it("leaves the records in place while they are refetched", async () => {
    const wrapper = await mount({
      records: [{ slug: "avenger", name: "Avenger" }],
      loading: true,
      skeletonRows: 5,
    });

    expect(skeletonRows(wrapper)).toHaveLength(0);
  });

  it("stays out of the way of a table that did not ask for it", async () => {
    const wrapper = await mount({ records: [], loading: true });

    expect(skeletonRows(wrapper)).toHaveLength(0);
  });

  // Without the columns' own widths the placeholders lay out a second, narrower
  // table under the header they are meant to be waiting beneath.
  it("gives the placeholder cells the columns' widths", async () => {
    const wrapper = await mount({
      records: [],
      loading: true,
      skeletonRows: 1,
    });

    const cells = skeletonRows(wrapper)[0].findAll(".base-table-col");

    expect(cells).toHaveLength(columns.length);
    expect(cells[0].attributes("style")).toContain("width: 200px");
  });

  // A cell holding a thumbnail is both taller and a different shape than a line
  // of text, so a bar stands in for neither its height nor what it holds.
  it("stands in for a column's media with a well of its height", async () => {
    const wrapper = await mountWithDefaults<typeof TableComponent>(
      TableComponent,
      {
        props: {
          records: [],
          loading: true,
          skeletonRows: 1,
          primaryKey: "slug",
          columns: [
            { name: "image", label: "", skeletonMedia: "50px" },
            ...columns,
          ],
        },
      },
    );

    const row = wrapper.get('[data-test="base-table-skeleton-row"]');
    const wells = row.findAll(".skeleton-well");

    expect(wells).toHaveLength(1);
    expect(wells[0].attributes("style")).toContain("height: 50px");
    expect(row.findAll(".skeleton-bar")).toHaveLength(columns.length);
  });

  // The last cell of a row with actions holds buttons, and those set the row's
  // height rather than the text beside them.
  it("reserves the control height for a table that carries actions", async () => {
    const withActions = await mountWithDefaults<typeof TableComponent>(
      TableComponent,
      {
        props: {
          records: [],
          loading: true,
          skeletonRows: 1,
          primaryKey: "slug",
          columns,
        },
        slots: { actions: "<button>edit</button>" },
      },
    );

    expect(
      withActions.get('[data-test="base-table-skeleton-row"]').classes(),
    ).toContain("base-table__skeleton-row--with-controls");

    const plain = await mount({ records: [], loading: true, skeletonRows: 1 });

    expect(
      plain.get('[data-test="base-table-skeleton-row"]').classes(),
    ).not.toContain("base-table__skeleton-row--with-controls");
  });

  // A table on its own keeps its spinner over its placeholders - nothing else
  // is going to say it is loading. Holding it back is the job of a list that
  // shows one already, and that case lives in useListGeometry's spec.
  it("keeps its own spinner over placeholders it stands alone with", async () => {
    const wrapper = await mount({
      records: [],
      loading: true,
      skeletonRows: 3,
    });

    expect(wrapper.find(".base-table__loader").exists()).toBe(true);
  });

  it("keeps the placeholders out of the reading order", async () => {
    const wrapper = await mount({
      records: [],
      loading: true,
      skeletonRows: 2,
    });

    expect(skeletonRows(wrapper)[0].attributes("aria-hidden")).toBe("true");
  });
});
