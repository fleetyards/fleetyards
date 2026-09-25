import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useFleetStore, FleetSortFieldsEnum } from "@/frontend/stores/fleet";
import { useFleetSortFields } from "./useFleetSortFields";

const names = (fields: { name: unknown }[]) =>
  fields.map((field) => field.name);

describe("useFleetSortFields", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("offers the count while the list is grouped", () => {
    const store = useFleetStore();
    store.grouped = true;
    store.setSortFields([FleetSortFieldsEnum.NAME, FleetSortFieldsEnum.COUNT]);

    expect(names(useFleetSortFields().value)).toEqual([
      "modelName",
      "vehiclesCount",
    ]);
  });

  it("hides the count once the list is ungrouped, even as the current sort", () => {
    const store = useFleetStore();
    store.setSortFields([FleetSortFieldsEnum.NAME, FleetSortFieldsEnum.COUNT]);
    const fields = useFleetSortFields({ include: "vehiclesCount desc" });

    store.grouped = false;

    expect(names(fields.value)).toEqual(["modelName"]);
  });

  it("lists the count among every sort for the display options", () => {
    const store = useFleetStore();
    store.grouped = false;

    expect(names(useFleetSortFields({ all: true }).value)).toEqual(
      Object.values(FleetSortFieldsEnum),
    );
  });
});
