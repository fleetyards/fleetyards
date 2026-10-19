import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { defineComponent, h } from "vue";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  summarizeShipFilters,
  useShipFilterSummary,
} from "./useShipFilterSummary";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key, tExists: () => false }),
}));

describe("ship filter summaries", () => {
  it("combines both bounds even when the maximum comes first and keeps zero", () => {
    expect(
      summarizeShipFilters(
        { cargoLteq: "32", cargoGteq: "0", lengthLteq: "80" },
        (key) => key,
      ),
    ).toEqual([
      { id: "cargo", label: "cargo: 0–32", keys: ["cargoGteq", "cargoLteq"] },
      {
        id: "length",
        label: "length: ≤ 80",
        keys: ["lengthGteq", "lengthLteq"],
      },
    ]);
  });

  it("omits view, sharing, sorting, pagination and empty values", () => {
    expect(
      summarizeShipFilters(
        {
          share: "secret",
          plaque: "true",
          s: "cargo desc",
          sorts: ["name asc"],
          page: "2",
          perPage: "48",
          tab: "list",
          view: "grid",
          direction: "asc",
          fleetchart: "true",
          nameCont: "",
          sizeIn: [],
        },
        (key) => key,
      ),
    ).toEqual([]);
  });

  it("keeps multiple selections together and does not drop false", () => {
    expect(
      summarizeShipFilters(
        { manufacturerIn: ["anvil", "aegis"], onSaleEq: "false" },
        (key) => key,
      ).map((item) => item.label),
    ).toEqual(["manufacturerIn: anvil, aegis", "onSaleEq: false"]);
  });

  it("removes both range bounds, resets pagination and preserves the view and other filters", async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [{ path: "/ships", component: { template: "<div />" } }],
    });
    await router.push({
      path: "/ships",
      query: {
        cargoGteq: "0",
        cargoLteq: "32",
        sizeIn: "large",
        page: "3",
        perPage: "48",
        s: "name asc",
        view: "grid",
      },
    });
    let summary: ReturnType<typeof useShipFilterSummary> | undefined;
    const component = defineComponent({
      setup() {
        summary = useShipFilterSummary();
        return () => h("div");
      },
    });
    const wrapper = await mountWithDefaults(component, { plugins: [router] });
    await summary!.activeFilters.value
      .find((item) => item.id === "cargo")!
      .remove();
    expect(router.currentRoute.value.query).toEqual({
      sizeIn: "large",
      perPage: "48",
      s: "name asc",
      view: "grid",
    });
    wrapper.unmount();
  });
});
