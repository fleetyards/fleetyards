/*
 * Phase 0 of the FilterGroup redesign (docs/exec-plans/filter-group-redesign.md).
 *
 * These pin the behaviour the rebuild must not regress. They are deliberately
 * written against the component as it is today -- including the DOM contract
 * CargoGrids.spec.ts depends on -- so that the rebuild has something to fail
 * against rather than being verified by eye.
 */
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

const options = [
  { value: "c", label: "Caterpillar" },
  { value: "a", label: "Aurora" },
  { value: "b", label: "Banu Merchantman" },
];

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const mount = (props: Record<string, any> = {}) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { name: "ships", options, ...props },
  });

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const labelsIn = (wrapper: any, root = "") =>
  wrapper
    .findAll(`${root} .filter-group-item-label`)
    .map((node: { text: () => string }) => node.text());

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
     * Pins a defect, not an intention. `sort()` exists and `availableOptions`
     * applies it, but the popover renders `filteredOptions`, which returns
     * `internalOptions` untouched -- so the list a user reads is in arrival
     * order and only the selected rows come out sorted (see the test below).
     *
     * The rebuild should make this list sorted and flip this assertion. Until
     * it does, the current behaviour is written down rather than assumed.
     */
    it("renders the popover list in arrival order, because the sort never reaches it", async () => {
      const wrapper = await mount();

      expect(labelsIn(wrapper, '[id^="ships-options-"]')).toEqual([
        "Caterpillar",
        "Aurora",
        "Banu Merchantman",
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
        .find('[id^="ships-options-"] .filter-group-item')
        .trigger("click");

      // The first row is Caterpillar, not Aurora -- arrival order, per above.
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
});
