import { describe, expect, it } from "vitest";
import { QueryClient } from "@tanstack/vue-query";
import {
  type Import,
  ImportStatusEnum,
  ImportTypeEnum,
  getModelQueryKey,
  getModelsQueryKey,
} from "@/services/fyAdminApi";
import { refreshImportedRecords } from "./useImportUpdates";

const MODEL_ID = "0f2c0f2c-0f2c-0f2c-0f2c-0f2c0f2c0f2c";

const anImport = (type: ImportTypeEnum, status: ImportStatusEnum) =>
  ({
    id: "import-1",
    type,
    status,
    createdAt: "2026-11-21T00:00:00Z",
    updatedAt: "2026-11-21T00:00:00Z",
  }) as Import;

const seeded = () => {
  const queryClient = new QueryClient();

  queryClient.setQueryData(getModelQueryKey(MODEL_ID), { id: MODEL_ID });
  queryClient.setQueryData(getModelsQueryKey({ page: "1" }), { items: [] });

  const isStale = (key: readonly unknown[]) =>
    queryClient.getQueryState(key)?.isInvalidated;

  return { queryClient, isStale };
};

describe("refreshImportedRecords", () => {
  it("refetches the model once a single ship matrix reload finishes", () => {
    const { queryClient, isStale } = seeded();

    refreshImportedRecords(
      queryClient,
      anImport(ImportTypeEnum.IMPORTS_MODEL_IMPORT, ImportStatusEnum.FINISHED),
    );

    expect(isStale(getModelQueryKey(MODEL_ID))).toBe(true);
    expect(isStale(getModelsQueryKey({ page: "1" }))).toBe(true);
  });

  it("refetches models after an sc data reload", () => {
    const { queryClient, isStale } = seeded();

    refreshImportedRecords(
      queryClient,
      anImport(
        ImportTypeEnum.IMPORTS_SC_DATA_MODEL_IMPORT,
        ImportStatusEnum.FINISHED,
      ),
    );

    expect(isStale(getModelQueryKey(MODEL_ID))).toBe(true);
  });

  it("waits until the run has finished", () => {
    const { queryClient, isStale } = seeded();

    refreshImportedRecords(
      queryClient,
      anImport(ImportTypeEnum.IMPORTS_MODEL_IMPORT, ImportStatusEnum.STARTED),
    );

    expect(isStale(getModelQueryKey(MODEL_ID))).toBe(false);
  });

  it("leaves models alone for unrelated imports", () => {
    const { queryClient, isStale } = seeded();

    refreshImportedRecords(
      queryClient,
      anImport(ImportTypeEnum.IMPORTS_PAINTS_IMPORT, ImportStatusEnum.FINISHED),
    );

    expect(isStale(getModelQueryKey(MODEL_ID))).toBe(false);
  });
});
