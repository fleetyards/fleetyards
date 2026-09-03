import { flushPromises, mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { defineComponent, ref, type Component } from "vue";
import BaseTable from "@/shared/components/base/Table/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import ListGroup from "@/shared/components/ListGroup/index.vue";
import { provideListGeometry, useReportListGeometry } from "./useListGeometry";
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

// Stands in for FilteredList around a list of rows rather than a table.
const listGroupHost = (records: Row[], frameSpinner = true) =>
  defineComponent({
    components: { ListGroup: ListGroup as unknown as Component },
    setup() {
      provideListGeometry("docks", ref(4), ref(frameSpinner));

      return {
        items: records.map((entry) => ({ id: entry.slug, name: entry.name })),
        loading: !records.length,
        // The first row is the one being edited, which is as tall as the panel
        // inside it.
        expandedId: records[0]?.slug,
      };
    },
    template: `
      <ListGroup :items="items" :loading="loading" :expanded-id="expandedId">
        <template #display="{ item }">
          <span>{{ item.name }}</span>
        </template>
      </ListGroup>
    `,
  });

// Stands in for a page that draws its list inside a FilteredList's slot: the
// provide happens in a child of it, so there is nothing to inject and the list
// is named instead.
const namedHost = (records: Row[]) =>
  defineComponent({
    setup() {
      const list = ref<HTMLElement>();

      useReportListGeometry("row", list, {
        name: "ships",
        ready: () => !!records.length,
        pick: (host) => host.firstElementChild,
      });

      return { list, records };
    },
    template: `
      <ul ref="list">
        <li v-for="record in records" :key="record.slug" class="row">
          {{ record.name }}
        </li>
      </ul>
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

  it("hands a list of rows the row count of the frame around it", async () => {
    const wrapper = await render(listGroupHost([]));

    expect(
      wrapper.findAll('[data-test="list-group-skeleton-row"]'),
    ).toHaveLength(4);
  });

  // An item wraps the expanded slot as well, and a placeholder stands in for
  // the row alone - so measuring the item would reserve an edit panel too. The
  // open row is skipped for the same reason: it is as tall as the panel inside
  // it, which says nothing about how tall a row of this list is.
  it("measures a closed row rather than the item around it", async () => {
    vi.spyOn(Element.prototype, "getBoundingClientRect").mockImplementation(
      function (this: Element) {
        if (!this.classList.contains("list-group__row")) {
          return { height: 220 } as DOMRect;
        }

        return {
          height: this.classList.contains("list-group__row--expanded")
            ? 180
            : 59,
        } as DOMRect;
      },
    );

    await render(listGroupHost([record, { slug: "hornet", name: "Hornet" }]));

    expect(heights()).toEqual([59]);
  });

  it("reserves a remembered row's height for a list's placeholders", async () => {
    stubHeight(59);
    await render(listGroupHost([record, { slug: "hornet", name: "Hornet" }]));
    vi.restoreAllMocks();

    const wrapper = await render(listGroupHost([]));

    expect(
      wrapper
        .get('[data-test="list-group-skeleton-row"]')
        .get(".list-group__row")
        .attributes("style"),
    ).toContain("height: 59px");
  });

  it("holds back a list's spinner while the frame shows one", async () => {
    const framed = await render(listGroupHost([]));

    expect(framed.find('[data-test="loader"]').exists()).toBe(false);

    const alone = await render(listGroupHost([], false));

    expect(alone.find('[data-test="loader"]').exists()).toBe(true);
  });

  // A page renders the FilteredList that provides the geometry, and inject only
  // ever looks upwards - so without a name its measurements went nowhere and
  // every load reserved the height of a row nobody had ever measured.
  it("files a named list's measurement without anything to inject", async () => {
    stubHeight(93);

    await render(namedHost([record]));

    expect(heights()).toEqual([93]);
    expect(
      Object.keys(useListGeometryStore().heights)[0].startsWith("ships:row:"),
    ).toBe(true);
  });

  it("has nothing to file for a list that is neither framed nor named", async () => {
    stubHeight(93);

    await render(
      defineComponent({
        setup() {
          const list = ref<HTMLElement>();

          useReportListGeometry("row", list, {
            ready: () => true,
            pick: (host) => host.firstElementChild,
          });

          return { list };
        },
        template: `<ul ref="list"><li class="row">Avenger</li></ul>`,
      }),
    );

    expect(heights()).toEqual([]);
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
