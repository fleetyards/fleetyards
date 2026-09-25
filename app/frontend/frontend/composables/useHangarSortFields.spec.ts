import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { useHangarStore, HangarSortFieldsEnum } from "@/frontend/stores/hangar";
import { useHangarSortFields } from "./useHangarSortFields";

const names = (fields: { name: unknown }[]) =>
  fields.map((field) => field.name);

describe("useHangarSortFields", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("offers the sorts picked in the display options", () => {
    useHangarStore().setSortFields([
      HangarSortFieldsEnum.MASS,
      HangarSortFieldsEnum.RANK,
    ]);

    expect(names(useHangarSortFields().value)).toEqual(["rank", "modelMass"]);
  });

  it("keeps the sort the hangar is in even when it was not picked", () => {
    useHangarStore().setSortFields([HangarSortFieldsEnum.NAME]);

    const fields = useHangarSortFields({ include: "modelBeam desc" });

    expect(names(fields.value)).toEqual(["name", "modelBeam"]);
  });

  it("offers every sort when asked for all of them", () => {
    useHangarStore().setSortFields([]);

    expect(names(useHangarSortFields({ all: true }).value)).toEqual(
      Object.values(HangarSortFieldsEnum),
    );
  });

  it("follows the pick as it changes", () => {
    const store = useHangarStore();
    const fields = useHangarSortFields();

    store.setSortFields([HangarSortFieldsEnum.CARGO]);

    expect(names(fields.value)).toEqual(["modelCargo"]);
  });
});
