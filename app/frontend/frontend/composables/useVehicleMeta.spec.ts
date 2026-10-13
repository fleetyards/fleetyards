import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { useVehicleMeta } from "./useVehicleMeta";
import { type Vehicle } from "@/services/fyApi";

const vehicle = {
  id: "vehicle-1",
  name: "Contorta",
  dedication: "Built rough, flown far.",
  model: { name: "Corsair", media: {}, description: "A gunship." },
} as unknown as Vehicle;

const Host = defineComponent({
  props: { vehicle: { type: Object, default: undefined } },
  setup(props) {
    useVehicleMeta(() => props.vehicle as Vehicle | undefined);
    return () => h("div");
  },
});

describe("useVehicleMeta", () => {
  it("names the ship and describes it by its dedication", async () => {
    document.head.innerHTML =
      '<title>Old</title><meta name="description" content="">' +
      '<meta property="og:title" content=""><meta property="og:description" content="">';

    await mountWithDefaults(Host, { props: { vehicle } });

    expect(document.title).toContain("Contorta");
    expect(
      document
        .querySelector('meta[property="og:description"]')
        ?.getAttribute("content"),
    ).toBe("Built rough, flown far.");
  });
});
