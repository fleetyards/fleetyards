import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import type { FeatureChange } from "@/services/fyAdminApi";

const changes = vi.hoisted(() => ({
  value: [] as FeatureChange[],
}));

// A computed rather than the hoisted object itself: the component reads `changes`
// through the template's ref auto-unwrapping, which a plain object does not get.
vi.mock("@/services/fyAdminApi", () => ({
  useAdminFeatureHistory: () => ({
    data: computed(() => changes.value),
    isLoading: ref(false),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    l: (value: string) => value,
  }),
}));

import FeatureHistory from "./index.vue";

const ROW = '[data-test="feature-history-row"]';

function change(overrides: Partial<FeatureChange> = {}): FeatureChange {
  return {
    id: "1",
    operation: "enable",
    gateName: "boolean",
    thing: "true",
    stateAfter: "on",
    source: "admin",
    actor: "someadmin",
    createdAt: "2026-09-16T00:00:00Z",
    ...overrides,
  };
}

const mountHistory = () =>
  mount(FeatureHistory, {
    props: { name: "friends" },
    global: {
      stubs: { BasePill: { template: "<span><slot /></span>" } },
    },
  });

describe("FeatureHistory", () => {
  it("says so when a flag has no recorded history", () => {
    changes.value = [];

    const wrapper = mountHistory();

    expect(
      wrapper.find('[data-test="feature-history-empty"]').exists(),
    ).toBe(true);
    expect(wrapper.findAll(ROW)).toHaveLength(0);
  });

  it("renders a row per change", () => {
    changes.value = [
      change({ id: "1" }),
      change({ id: "2", operation: "enable", gateName: "actor", thing: "User;abc" }),
    ];

    const wrapper = mountHistory();

    expect(wrapper.findAll(ROW)).toHaveLength(2);
  });

  // The operation alone reads the same for a flag opened to everyone and one
  // granted to a single person; the gate is what tells them apart.
  it("names the gate beside the operation", () => {
    changes.value = [change({ gateName: "actor", thing: "User;abc" })];

    const wrapper = mountHistory();

    expect(wrapper.find(ROW).text()).toContain("enable actor");
    expect(wrapper.find(ROW).text()).toContain("User;abc");
  });

  // sync, console and backfill have no actor, so the source has to stand alone
  // rather than leaving the row looking like missing data.
  it("shows the source without an actor", () => {
    changes.value = [change({ source: "sync", actor: null })];

    const wrapper = mountHistory();

    expect(wrapper.find(ROW).text()).toContain("labels.features.sources.sync");
    expect(wrapper.find(ROW).text()).not.toContain("labels.features.historyBy");
  });
});
