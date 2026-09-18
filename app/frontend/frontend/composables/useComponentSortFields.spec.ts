import { describe, expect, it, beforeEach, vi } from "vitest";
import { setActivePinia, createPinia } from "pinia";

// The composable reads `q[s]` so an active metric keeps its chip when the page
// it is on carries no row with that figure. Called outside a component there is
// no router to read, so one is stood in for.
const query = vi.hoisted(() => ({ value: {} as Record<string, string> }));

vi.mock("vue-router", () => ({
  useRoute: () => ({ query: query.value }),
}));
import { useComponentSortFields } from "./useComponentSortFields";
import { type Component } from "@/services/fyApi";

const component = (attrs: Partial<Component> = {}) =>
  ({ id: "id", name: "A Part", slug: "a-part", ...attrs }) as Component;

const labels = (records: Component[]) =>
  useComponentSortFields(records).value.map((column) => column.label);

describe("useComponentSortFields", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    query.value = {};
  });

  it("offers the sorts the server can order by", () => {
    expect(labels([component()])).toEqual([
      "Name",
      "Manufacturer",
      "Category",
      "Sub Type",
      "Size",
      "Grade",
    ]);
  });

  // `size` is a string ransacker -- ordering it puts 10 and 12 ahead of 2 --
  // so the column sorts through a numeric one of its own.
  it("sorts size numerically", () => {
    const size = useComponentSortFields([component()]).value.find(
      (column) => column.name === "size",
    );

    expect(size?.attributeKey).toBe("sizeOrder");
  });

  describe("the metrics", () => {
    // "Shields by HP" is the question the catalogue exists to answer.
    it("appear when the rows on screen carry one", () => {
      const records = [
        component({
          typeData: { maxHealth: 1000, maxRegen: 50 },
        } as Partial<Component>),
      ];

      expect(labels(records)).toContain("HP");
      expect(labels(records)).toContain("Regen");
    });

    it("stay away when no row carries one", () => {
      expect(labels([component()])).not.toContain("HP");
    });

    // Derived from the records alone, the chip vanished the moment a page held
    // no row carrying that figure -- leaving the list ordered by a setting with
    // no control left to see or undo it.
    it("keep the chip for the metric the list is ordered by", () => {
      query.value = { s: "maxHealth desc" };

      expect(labels([component()])).toContain("HP");
    });

    it("sort by the name the server whitelists", () => {
      const hp = useComponentSortFields([
        component({ typeData: { maxHealth: 1000 } } as Partial<Component>),
      ]).value.find((column) => column.label === "HP");

      expect(hp?.attributeKey).toBe("maxHealth");
    });
  });
});
