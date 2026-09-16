import { describe, it, expect } from "vitest";
import {
  getAdminFeaturesQueryKey,
  getAdminFeatureHistoryQueryKey,
} from "@/services/fyAdminApi";

// The features page invalidates only `getAdminFeaturesQueryKey()` after a
// mutation, and TanStack Query matches query keys by prefix unless `exact: true`
// is passed — so the open history panel refreshes off that same call, with no
// per-feature invalidation anywhere.
//
// That holds only while the generated history key keeps the list key as its
// prefix. If orval ever emits a different shape, the history would silently stop
// refreshing after a toggle and nothing else would notice.
describe("admin feature query keys", () => {
  it("nests the history key under the features list key", () => {
    const listKey = getAdminFeaturesQueryKey();
    const historyKey = getAdminFeatureHistoryQueryKey("friends");

    expect(historyKey.slice(0, listKey.length)).toEqual([...listKey]);
  });
});
