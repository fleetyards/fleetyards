import { describe, expect, it, vi } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { FilterOption } from "@/services/fyApi";

const currentUser = ref<{ hangarDefaultSort: string | null }>({
  hangarDefaultSort: null,
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useUpdateProfile: () => ({ mutateAsync: vi.fn(() => Promise.resolve()) }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get currentUser() {
      return currentUser.value;
    },
  }),
}));

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/settings", name: "settings", component: { template: "<div />" } },
  ],
});

import SettingsHangar from "./hangar.vue";

const mount = () => mountWithDefaults(SettingsHangar, { plugins: [router] });

const defaultSortSelect = async () =>
  (await mount())
    .findAllComponents({ name: "BaseSelect" })
    .find((select) => select.props("name") === "hangarDefaultSort")!;

describe("SettingsHangar", () => {
  // The standard order is flagship first, then name. No single sort gives
  // that, so it has to be an option of its own or nobody can go back to it.
  it("offers the standard order as the first choice", async () => {
    const options = (await defaultSortSelect()).props(
      "options",
    ) as FilterOption[];

    expect(options[0]).toMatchObject({
      value: null,
      label: "Standard (flagship first, then name)",
    });
  });

  it("offers the custom order one way only", async () => {
    const values = (
      (await defaultSortSelect()).props("options") as FilterOption[]
    ).map((option) => option.value);

    expect(values).toContain("rank asc");
    expect(values).not.toContain("rank desc");
    expect(values).toContain("name desc");
  });

  it("does not clear a choice by picking it again", async () => {
    expect((await defaultSortSelect()).props("nullable")).toBe(false);
  });
});
