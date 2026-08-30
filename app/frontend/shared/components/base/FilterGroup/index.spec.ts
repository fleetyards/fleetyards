/*
 * Phase 0 of the FilterGroup redesign (docs/exec-plans/filter-group-redesign.md).
 *
 * These pin the behaviour the rebuild must not regress. They are deliberately
 * written against the component as it is today -- including the DOM contract
 * CargoGrids.spec.ts depends on -- so that the rebuild has something to fail
 * against rather than being verified by eye.
 */
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

const options = [
  { value: "c", label: "Caterpillar" },
  { value: "a", label: "Aurora" },
  { value: "b", label: "Banu Merchantman" },
];

/*
 * FilterGroup is declared `<script setup generic="T">`, so its type is a
 * generic function component rather than a constructor, and mountWithDefaults
 * constrains to `new (...args: any) => any`. Casting to the shape the helper
 * asks for is contained to this file; widening the helper would reach the 40-odd
 * other specs that rely on its inference.
 *
 * The exposed methods are spelled out because four call sites reach them through
 * template refs -- see the plan's F5.
 */
const FilterGroup = Component as unknown as new (...args: never[]) => {
  $props: Record<string, unknown>;
  reset: () => void;
  clear: () => void;
  clearSearch: () => void;
};

const mount = (props: Record<string, unknown> = {}) =>
  mountWithDefaults<typeof FilterGroup>(FilterGroup, {
    props: { name: "ships", options, ...props },
  });

type Wrapper = Awaited<ReturnType<typeof mount>>;

const labelsIn = (wrapper: Wrapper, root = "") =>
  wrapper
    .findAll(`${root} .filter-group-item-label`)
    .map((node: { text: () => string }) => node.text());

// jsdom has no layout, so it does not implement scrollIntoView. Stubbed here
// rather than guarded in the component: it exists in every browser.
beforeAll(() => {
  Element.prototype.scrollIntoView = vi.fn();
});

afterEach(() => {
  vi.useRealTimers();
});

describe("FilterGroup", () => {
  describe("the DOM contract CargoGrids.spec.ts drives it through", () => {
    it("names the trigger filter-group-title", async () => {
      const wrapper = await mount();

      expect(wrapper.find('[data-test="filter-group-title"]').exists()).toBe(
        true,
      );
    });

    it("keeps the search box as the first input in the subtree", async () => {
      const wrapper = await mount({ searchable: true });

      const first = wrapper.findAll("input")[0];

      expect(first.attributes("name")).toContain("searchInput");
    });
  });

  describe("options", () => {
    /*
     * The flip side of the defect this spec used to pin: `sort()` ran in
     * `availableOptions` while the popover rendered `filteredOptions`, so the
     * selected rows came out alphabetical and the options a user picks from
     * stayed in whatever order the API returned them.
     */
    it("sorts the popover list by label, whatever order the options arrive in", async () => {
      const wrapper = await mount();

      expect(labelsIn(wrapper, '[id^="ships-options-"]')).toEqual([
        "Aurora",
        "Banu Merchantman",
        "Caterpillar",
      ]);
    });

    it("shows the selected label on the trigger rather than the raw value", async () => {
      const wrapper = await mount({ modelValue: "b" });

      expect(wrapper.find('[data-test="filter-group-title"]').text()).toContain(
        "Banu Merchantman",
      );
    });
  });

  describe("multiple", () => {
    it("renders the selected rows outside the popover while it is closed", async () => {
      const wrapper = await mount({ multiple: true, modelValue: ["a", "c"] });

      const selected = wrapper.find('[id^="ships-selected-"]');

      expect(selected.exists()).toBe(true);
      expect(
        selected
          .findAll(".filter-group-item-label")
          .map((n: { text: () => string }) => n.text()),
      ).toEqual(["Aurora", "Caterpillar"]);
    });

    it("does not render that second list when hideSelected is set", async () => {
      const wrapper = await mount({
        multiple: true,
        hideSelected: true,
        modelValue: ["a"],
      });

      expect(wrapper.find('[id^="ships-selected-"]').exists()).toBe(false);
    });

    it("adds to the selection rather than replacing it", async () => {
      const wrapper = await mount({ multiple: true, modelValue: ["a"] });

      await wrapper
        .findAll('[id^="ships-options-"] .filter-group-item')[2]
        .trigger("click");

      expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual([
        ["a", "c"],
      ]);
    });
  });

  describe("the imperative API four call sites depend on", () => {
    it("exposes reset, clear and clearSearch", async () => {
      const wrapper = await mount();

      expect(typeof wrapper.vm.reset).toBe("function");
      expect(typeof wrapper.vm.clear).toBe("function");
      expect(typeof wrapper.vm.clearSearch).toBe("function");
    });
  });

  describe("querying", () => {
    it("fetches an option that is selected but absent from the loaded page", async () => {
      const queryFn = vi
        .fn()
        .mockResolvedValue([{ value: "x", label: "Idris" }]);

      await mount({ options: undefined, queryFn, modelValue: "zeus" });

      expect(queryFn).toHaveBeenCalled();
      expect(
        queryFn.mock.calls.some(([params]) => params.missing === "zeus"),
      ).toBe(true);
    });

    it("debounces the search and resets to the first page", async () => {
      const queryFn = vi.fn().mockResolvedValue([]);
      const wrapper = await mount({
        options: undefined,
        queryFn,
        searchable: true,
      });

      queryFn.mockClear();
      vi.useFakeTimers();

      await wrapper.find("input").setValue("cat");
      await wrapper.find("input").trigger("input");

      expect(queryFn).not.toHaveBeenCalled();

      await vi.advanceTimersByTimeAsync(500);

      expect(queryFn).toHaveBeenCalledTimes(1);
      expect(queryFn.mock.calls[0][0]).toMatchObject({
        page: 1,
        search: "cat",
      });
    });

    it("offers more only while the response says there are more pages", async () => {
      const paged = (currentPage: number, totalPages: number) => ({
        data: [],
        meta: { pagination: { currentPage, totalPages } },
      });
      const queryFn = vi.fn().mockResolvedValue(paged(1, 3));

      const wrapper = await mount({
        options: undefined,
        queryFn,
        queryResponseFormatter: (r: { data: unknown[] }) => r.data,
        paginated: true,
      });

      expect(wrapper.find(".filter-group-fetch-more").exists()).toBe(true);
    });

    it("hides the fetch-more row on the last page", async () => {
      const queryFn = vi.fn().mockResolvedValue({
        data: [],
        meta: { pagination: { currentPage: 3, totalPages: 3 } },
      });

      const wrapper = await mount({
        options: undefined,
        queryFn,
        queryResponseFormatter: (r: { data: unknown[] }) => r.data,
        paginated: true,
      });

      expect(wrapper.find(".filter-group-fetch-more").exists()).toBe(false);
    });
  });
  describe("combobox semantics", () => {
    it("makes the trigger a button that announces itself as a combobox", async () => {
      const wrapper = await mount();
      const trigger = wrapper.find('[data-test="filter-group-title"]');

      expect(trigger.element.tagName).toBe("BUTTON");
      expect(trigger.attributes("role")).toBe("combobox");
      expect(trigger.attributes("aria-haspopup")).toBe("listbox");
      expect(trigger.attributes("aria-expanded")).toBe("false");
    });

    it("flips aria-expanded when it opens", async () => {
      const wrapper = await mount();

      await wrapper.find('[data-test="filter-group-title"]').trigger("click");

      expect(
        wrapper
          .find('[data-test="filter-group-title"]')
          .attributes("aria-expanded"),
      ).toBe("true");
    });

    it("points the label at the trigger when there is no search box", async () => {
      const wrapper = await mount();

      expect(wrapper.find("label").attributes("for")).toBe(
        wrapper.find('[data-test="filter-group-title"]').attributes("id"),
      );
    });

    it("still points the label at the search box when there is one", async () => {
      const wrapper = await mount({ searchable: true, label: "Ships" });

      expect(wrapper.find("label").attributes("for")).toContain("searchInput");
    });

    it("gives every row an option role and its selected state", async () => {
      const wrapper = await mount({ modelValue: "a" });
      const rows = wrapper.findAll('[role="option"]');

      expect(rows).toHaveLength(3);
      expect(rows.map((r) => r.attributes("aria-selected"))).toEqual([
        "true",
        "false",
        "false",
      ]);
    });

    it("marks the listbox multi-selectable only when it is", async () => {
      const single = await mount();
      const many = await mount({ multiple: true });

      expect(
        single.find('[role="listbox"]').attributes("aria-multiselectable"),
      ).toBe("false");
      expect(
        many.find('[role="listbox"]').attributes("aria-multiselectable"),
      ).toBe("true");
    });
  });

  describe("keyboard", () => {
    const open = async () => {
      const wrapper = await mount();
      await wrapper.trigger("keydown", { key: "ArrowDown" });
      return wrapper;
    };

    const activeLabel = (wrapper: {
      find: (s: string) => { exists: () => boolean; text: () => string };
    }) => wrapper.find(".filter-group-item--focused").text();

    it("opens on ArrowDown and points at the first row", async () => {
      const wrapper = await open();

      expect(
        wrapper
          .find('[data-test="filter-group-title"]')
          .attributes("aria-expanded"),
      ).toBe("true");
      expect(activeLabel(wrapper)).toContain("Aurora");
    });

    it("opens on ArrowUp and points at the last row", async () => {
      const wrapper = await mount();

      await wrapper.trigger("keydown", { key: "ArrowUp" });

      expect(activeLabel(wrapper)).toContain("Caterpillar");
    });

    it("wraps around both ends", async () => {
      const wrapper = await open();

      await wrapper.trigger("keydown", { key: "ArrowUp" });
      expect(activeLabel(wrapper)).toContain("Caterpillar");

      await wrapper.trigger("keydown", { key: "ArrowDown" });
      expect(activeLabel(wrapper)).toContain("Aurora");
    });

    it("jumps to the ends with Home and End", async () => {
      const wrapper = await open();

      await wrapper.trigger("keydown", { key: "End" });
      expect(activeLabel(wrapper)).toContain("Caterpillar");

      await wrapper.trigger("keydown", { key: "Home" });
      expect(activeLabel(wrapper)).toContain("Aurora");
    });

    it("publishes the pointed-at row through aria-activedescendant", async () => {
      const wrapper = await open();

      expect(
        wrapper
          .find('[data-test="filter-group-title"]')
          .attributes("aria-activedescendant"),
      ).toBe(wrapper.find(".filter-group-item--focused").attributes("id"));
    });

    it("selects the pointed-at row on Enter", async () => {
      const wrapper = await open();

      await wrapper.trigger("keydown", { key: "ArrowDown" });
      await wrapper.trigger("keydown", { key: "Enter" });

      expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual(["b"]);
    });

    it("closes on Escape without selecting", async () => {
      const wrapper = await open();

      await wrapper.trigger("keydown", { key: "Escape" });

      expect(
        wrapper
          .find('[data-test="filter-group-title"]')
          .attributes("aria-expanded"),
      ).toBe("false");
      expect(wrapper.emitted("update:modelValue")).toBeUndefined();
    });

    it("jumps to a row by typing its first letters", async () => {
      const wrapper = await mount();

      await wrapper.trigger("keydown", { key: "b" });
      await wrapper.trigger("keydown", { key: "a" });

      expect(activeLabel(wrapper)).toContain("Banu Merchantman");
    });

    it("leaves typing to the search box when the group is searchable", async () => {
      const wrapper = await mount({ searchable: true });

      await wrapper.find('[data-test="filter-group-title"]').trigger("click");
      await wrapper.trigger("keydown", { key: "b" });

      expect(wrapper.find(".filter-group-item--focused").exists()).toBe(false);
    });
  });
});
