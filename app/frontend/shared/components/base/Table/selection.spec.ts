import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { LONG_PRESS_MS } from "@/shared/composables/useLongPress";
import Component from "./index.vue";
import { type BaseTableCol } from "./types";

type Row = { slug: string; name: string };

const columns: BaseTableCol<Row>[] = [{ name: "name", label: "Name" }];

const TableComponent = Component as unknown as new (...args: unknown[]) => {
  $props: {
    records: Row[];
    columns: BaseTableCol<Row>[];
    primaryKey: keyof Row;
    selectable?: boolean;
    rowClickable?: boolean;
    rowDisabled?: (record: Row) => boolean;
  };
};

const touch = (type: string, clientX?: number) => {
  const event = new Event(type, { bubbles: true, cancelable: true });

  Object.defineProperty(event, "touches", {
    value: clientX === undefined ? [] : [{ clientX, clientY: 0 }],
  });

  return event;
};

const records = [
  { slug: "a", name: "A" },
  { slug: "b", name: "B" },
];

let mounted: { unmount: () => void } | undefined;

// jsdom lays nothing out, so its document is 0px wide and every mount is a
// phone - which is the layout these tests are about.
const mount = async (rowDisabled?: (record: Row) => boolean) => {
  const wrapper = await mountWithDefaults<typeof TableComponent>(
    TableComponent,
    {
      props: {
        columns,
        primaryKey: "slug",
        records,
        selectable: true,
        rowClickable: true,
        rowDisabled,
      },
      slots: {
        "selected-actions": () => h("button", { "data-test": "bulk-go" }),
        "col-name": ({ record }: { record: Row }) =>
          h("a", { href: `/ships/${record.slug}`, "data-test": "name-link" }, [
            record.name,
          ]),
      },
      attachTo: document.getElementById("app")!,
    },
  );

  await flushPromises();
  mounted = wrapper;

  return wrapper;
};

type Mounted = Awaited<ReturnType<typeof mount>>;

const rows = (wrapper: Mounted) =>
  wrapper
    .findAll(".base-table-row")
    .filter((row) => !row.element.closest(".base-table-header"));

const hold = async (wrapper: Mounted, index: number) => {
  const row = rows(wrapper)[index].element;

  row.dispatchEvent(touch("touchstart", 100));
  vi.advanceTimersByTime(LONG_PRESS_MS);
  row.dispatchEvent(touch("touchend"));
  await flushPromises();
};

const boxes = (wrapper: Mounted) =>
  wrapper
    .findAll('[data-test="checkbox-item"]')
    .map((box) => (box.element as HTMLInputElement).checked);

beforeEach(() => {
  document.body.innerHTML = '<div id="header-left"></div><div id="app"></div>';
  vi.useFakeTimers();
});

afterEach(() => {
  mounted?.unmount();
  mounted = undefined;
  vi.useRealTimers();
});

describe("BaseTable on a phone", () => {
  it("shows no checkboxes until a row is held", async () => {
    const wrapper = await mount();

    expect(boxes(wrapper)).toEqual([]);

    await hold(wrapper, 1);

    expect(boxes(wrapper)).toEqual([false, true]);
  });

  it("picks a tapped row while selecting instead of following it", async () => {
    const wrapper = await mount();

    await hold(wrapper, 0);
    vi.advanceTimersByTime(500);
    await rows(wrapper)[1].trigger("click");

    expect(boxes(wrapper)).toEqual([true, true]);
    expect(wrapper.emitted("row-click")).toBeUndefined();
  });

  it("follows a tapped row when nothing is picked", async () => {
    const wrapper = await mount();

    await rows(wrapper)[0].trigger("click");

    expect(wrapper.emitted("row-click")).toHaveLength(1);
  });

  it("hands its bulk actions to the header while selecting", async () => {
    const wrapper = await mount();

    await hold(wrapper, 0);

    const header = document.getElementById("header-left")!;

    expect(header.querySelector(".navigation-header-takeover")).not.toBeNull();
    expect(header.querySelector('[data-test="bulk-go"]')).not.toBeNull();
  });

  it("picks a row from its linked name while selecting, without following it", async () => {
    const wrapper = await mount();

    await hold(wrapper, 0);
    vi.advanceTimersByTime(500);

    const link = wrapper.findAll('[data-test="name-link"]')[1].element;
    const click = new MouseEvent("click", { bubbles: true, cancelable: true });
    link.dispatchEvent(click);
    await flushPromises();

    expect(click.defaultPrevented).toBe(true);
    expect(boxes(wrapper)).toEqual([true, true]);
  });

  it("keeps a held row picked when the finger lifts", async () => {
    const wrapper = await mount();

    await hold(wrapper, 0);
    await rows(wrapper)[0].trigger("click");

    expect(boxes(wrapper)).toEqual([true, false]);
  });

  it("does not start a selection from a disabled row", async () => {
    const wrapper = await mount((record) => record.slug === "a");

    await hold(wrapper, 0);

    expect(boxes(wrapper)).toEqual([]);
  });
});
