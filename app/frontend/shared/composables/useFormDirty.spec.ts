import { describe, expect, it } from "vitest";
import { ref } from "vue";
import { useFormDirty } from "./useFormDirty";

describe("useFormDirty", () => {
  it("reports a changed value and clears once it is changed back", () => {
    const values = ref({ name: "Wayfinder" });
    const dirty = useFormDirty(values, { name: "Wayfinder" });

    values.value = { name: "Pathfinder" };
    expect(dirty.value).toBe(true);

    values.value = { name: "Wayfinder" };
    expect(dirty.value).toBe(false);
  });

  it("reads an emptied field as unchanged from one that started empty", () => {
    const values = ref<Record<string, unknown>>({});
    const dirty = useFormDirty(values, {
      public: undefined,
      name: undefined,
      groupIds: undefined,
    });

    values.value = { public: false, name: "", groupIds: [] };

    expect(dirty.value).toBe(false);
  });

  it("reports a field the form opened without", () => {
    const values = ref<Record<string, unknown>>({ name: "Wayfinder" });
    const dirty = useFormDirty(values, { name: "Wayfinder" });

    values.value = { name: "Wayfinder", notes: "Ursa in the bay" };

    expect(dirty.value).toBe(true);
  });

  it("still reports a toggle switched off from on", () => {
    const values = ref({ public: false });
    const dirty = useFormDirty(values, { public: true });

    expect(dirty.value).toBe(true);
  });

  // A form that re-fills itself from a refetched record compares with the
  // record as it is now.
  it("follows initial values given as a getter", () => {
    const record = ref({ name: "Wayfinder" });
    const values = ref({ name: "Pathfinder" });
    const dirty = useFormDirty(values, () => record.value);

    expect(dirty.value).toBe(true);

    record.value = { name: "Pathfinder" };
    expect(dirty.value).toBe(false);
  });
});
