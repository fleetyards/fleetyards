import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { usePresence } from "@/shared/composables/usePresence";
import type { RelationshipRow } from "@/frontend/components/Relationships/types";

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    l: (value: string) => value,
    timeDistance: (value: string) => value,
  }),
}));

import Component from "./index.vue";

const USER = "11111111-1111-1111-1111-111111111111";

const friendRow = {
  id: "row-1",
  handle: "gustav",
  label: "gustav",
  userId: USER,
  online: true,
  state: "accepted",
  direction: "incoming",
  createdAt: "2026-09-20T10:00:00Z",
} as RelationshipRow;

const allyRow = {
  id: "row-2",
  handle: "acme",
  label: "ACME",
  state: "accepted",
  direction: "incoming",
  createdAt: "2026-09-20T10:00:00Z",
} as RelationshipRow;

beforeEach(() => {
  usePresence().resetPresence();
});

describe("RelationshipTable", () => {
  it("draws a dot for a friend", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { rows: [friendRow], kind: "user" },
    });

    expect(wrapper.find(".presence-dot").exists()).toBe(true);
  });

  it("draws no dot on the alliances view, which shares this table", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { rows: [{ ...friendRow, ...allyRow }], kind: "fleet" },
    });

    expect(wrapper.find(".presence-dot").exists()).toBe(false);
  });

  it("draws no dot for a row the API answered nothing for", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { rows: [allyRow], kind: "user" },
    });

    expect(wrapper.find(".presence-dot").exists()).toBe(false);
  });

  it("greys the dot when a transition says the friend left", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { rows: [friendRow], kind: "user" },
    });

    expect(wrapper.find(".presence-dot-online").exists()).toBe(true);

    usePresence().applyPresence({ userId: USER, online: false });
    await wrapper.vm.$nextTick();

    expect(wrapper.find(".presence-dot-offline").exists()).toBe(true);
  });
});
