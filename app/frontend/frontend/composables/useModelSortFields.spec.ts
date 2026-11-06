import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { HangarSortFieldsEnum } from "@/frontend/stores/hangar";
import { ModelSortFieldsEnum } from "@/frontend/stores/models";
import { useModelSortFields } from "./useModelSortFields";
import labels from "@/translations/en/labels.json";

const OWNER_ONLY_SORTS: string[] = [HangarSortFieldsEnum.RANK];

const asModelSort = (hangarSort: string) => {
  const unprefixed = hangarSort.replace(/^model/, "");

  return unprefixed.charAt(0).toLowerCase() + unprefixed.slice(1);
};

describe("useModelSortFields", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("offers every sort the hangar has, bar the owner's own order", () => {
    const names = useModelSortFields({ all: true }).value.map(
      (field) => field.name,
    );

    const expected = Object.values(HangarSortFieldsEnum)
      .filter((sort) => !OWNER_ONLY_SORTS.includes(sort))
      .map(asModelSort);

    expect(names).toEqual(expected);
  });

  it("has a label for every sort", () => {
    const columns: Record<string, string> =
      labels.en.labels.models.table.columns;

    Object.values(ModelSortFieldsEnum)
      .filter((sort) => sort !== ModelSortFieldsEnum.NAME)
      .forEach((sort) => expect(columns[sort]).toBeTruthy());
  });
});
