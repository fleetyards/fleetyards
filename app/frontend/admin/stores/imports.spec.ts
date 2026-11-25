import { beforeEach, describe, expect, it } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import {
  type Import,
  ImportStatusEnum,
  ImportTypeEnum,
} from "@/services/fyAdminApi";
import { useImportsStore } from "./imports";

const anImport = (status: ImportStatusEnum, updatedAt: string): Import => ({
  id: "import-1",
  type: ImportTypeEnum.IMPORTS_SC_DATA_ALL_IMPORT,
  status,
  createdAt: "2026-11-25T09:00:00Z",
  updatedAt,
});

describe("imports store", () => {
  beforeEach(() => setActivePinia(createPinia()));

  it("keeps a broadcast the list has not caught up with", () => {
    const store = useImportsStore();

    store.upsertImport(
      anImport(ImportStatusEnum.FINISHED, "2026-11-25T10:00:03Z"),
    );
    store.seedImports([
      anImport(ImportStatusEnum.STARTED, "2026-11-25T10:00:00Z"),
    ]);

    expect(store.activeImports).toEqual([]);
  });

  it("takes a newer list over a stale broadcast", () => {
    const store = useImportsStore();

    store.seedImports([
      anImport(ImportStatusEnum.CREATED, "2026-11-25T10:00:00Z"),
    ]);
    store.seedImports([
      anImport(ImportStatusEnum.STARTED, "2026-11-25T10:00:03Z"),
    ]);

    expect(store.imports["import-1"].status).toBe(ImportStatusEnum.STARTED);
  });
});
