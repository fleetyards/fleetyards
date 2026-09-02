import { flushPromises, mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, ref, type Component } from "vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import { provideListGeometry } from "./useListGeometry";
import { useListGeometryStore } from "@/shared/stores/listGeometry";
import type { BaseTableCol } from "@/shared/components/base/Table/types";

type Row = { slug: string; name: string };

const columns: BaseTableCol<Row>[] = [
  { name: "name", label: "Name" },
  { name: "focus", label: "Focus" },
];

const record = { slug: "avenger", name: "Avenger" };

// A real store rather than the testing one: what is under test is the round
// trip through it, and the testing pinia stubs the action that writes.
beforeEach(() => {
  setActivePinia(createPinia());
});

afterEach(() => {
  vi.restoreAllMocks();
});

const render = async (component: Component) => {
  const wrapper = mount(component, {
    global: { directives: { Tooltip: {} } },
  });

  await flushPromises();

  return wrapper;
};

// Stands in for FilteredList: the geometry only reaches a list through whatever
// frames it.
const listHost = (records: Row[], frameSpinner = true) =>
  defineComponent({
    components: { BaseTable: BaseTable as unknown as Component },
    setup() {
      provideListGeometry("ships", ref(4), ref(frameSpinner));

      return { columns, records, loading: !records.length };
    },
    template: `
      <BaseTable
        :records="records"
        :columns="columns"
        primary-key="slug"
        :loading="loading"
      />
    `,
  });

const gridHost = (records: Row[]) =>
  defineComponent({
    components: { Grid: Grid as unknown as Component },
    setup() {
      provideListGeometry("ships", ref(4), ref(true));

      return { records };
    },
    template: `
      <Grid :records="records" primary-key="slug">
        <template #default="{ record }">
          <div class="card">{{ record.name }}</div>
        </template>
      </Grid>
    `,
  });

const stubHeight = (height: number) =>
  vi
    .spyOn(Element.prototype, "getBoundingClientRect")
    .mockReturnValue({ height } as DOMRect);

const heights = () => Object.values(useListGeometryStore().heights);

describe("useListGeometry", () => {
  it("hands a table the page size of the list around it", async () => {
    const wrapper = await render(listHost([]));

    expect(
      wrapper.findAll('[data-test="base-table-skeleton-row"]'),
    ).toHaveLength(4);
  });

  // The measurement is the whole point: a row's height comes from its own
  // content, so the table that rendered it is the only thing that knows.
  it("remembers what a rendered row measured", async () => {
    stubHeight(93);

    await render(listHost([record]));

    expect(heights()).toEqual([93]);
  });

  // The header is a row of the same class, and it is both shorter than a record
  // and no indication of how tall one is.
  it("measures a record's row rather than the header", async () => {
    vi.spyOn(Element.prototype, "getBoundingClientRect").mockImplementation(
      function (this: Element) {
        return {
          height: this.closest(".base-table-header") ? 45 : 93,
        } as DOMRect;
      },
    );

    await render(listHost([record]));

    expect(heights()).toEqual([93]);
  });

  it("reserves that height for the next load's placeholders", async () => {
    stubHeight(93);
    await render(listHost([record]));
    vi.restoreAllMocks();

    const wrapper = await render(listHost([]));

    expect(
      wrapper.get('[data-test="base-table-skeleton-row"]').attributes("style"),
    ).toContain("height: 93px");
  });

  // A cell carries the card's outer margin as well, so measuring the cell would
  // reserve that margin twice over.
  it("measures a grid's card rather than the cell around it", async () => {
    vi.spyOn(Element.prototype, "getBoundingClientRect").mockImplementation(
      function (this: Element) {
        return {
          height: this.classList.contains("card") ? 286 : 307,
        } as DOMRect;
      },
    );

    await render(gridHost([record]));

    expect(heights()).toEqual([286]);
  });

  // One list can be drawn both ways - the ships list is a grid or a table on
  // the reader's say - and a card is not as tall as a row. Under one key the
  // second shape to render would hand its height to the first.
  it("keeps a card's height apart from a row's", async () => {
    vi.spyOn(Element.prototype, "getBoundingClientRect").mockImplementation(
      function (this: Element) {
        return {
          height: this.classList.contains("card") ? 290 : 93,
        } as DOMRect;
      },
    );

    await render(gridHost([record]));
    await render(listHost([record]));

    const byShape = Object.fromEntries(
      Object.entries(useListGeometryStore().heights).map(([key, height]) => [
        key.split(":")[1],
        height,
      ]),
    );

    expect(byShape).toEqual({ card: 290, row: 93 });
  });

  // One spinner between them: the frame's, over the placeholders, unless the
  // list is one of those that hides it in favour of the table's own.
  it("holds back the table's spinner while the frame shows one", async () => {
    const framed = await render(listHost([]));

    expect(framed.find(".base-table__loader").exists()).toBe(false);

    const alone = await render(listHost([], false));

    expect(alone.find(".base-table__loader").exists()).toBe(true);
  });

  it("stays out of the way of a table with no list around it", async () => {
    const wrapper = await render(
      defineComponent({
        components: { BaseTable: BaseTable as unknown as Component },
        setup() {
          return { columns, records: [] as Row[] };
        },
        template: `
          <BaseTable
            :records="records"
            :columns="columns"
            primary-key="slug"
            loading
          />
        `,
      }),
    );

    expect(
      wrapper.findAll('[data-test="base-table-skeleton-row"]'),
    ).toHaveLength(0);
  });
});
