import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

let enabled = false;

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => enabled }),
}));

vi.mock("@/frontend/components/Home/Legacy/index.vue", async () => {
  const { defineComponent, h } = await import("vue");
  return {
    default: defineComponent({
      render: () => h("div", { "data-test": "legacy" }),
    }),
  };
});
vi.mock("@/frontend/components/Home/Landing/index.vue", async () => {
  const { defineComponent, h } = await import("vue");
  return {
    default: defineComponent({
      render: () => h("div", { "data-test": "landing" }),
    }),
  };
});
vi.mock("@/frontend/components/Home/Dashboard/index.vue", async () => {
  const { defineComponent, h } = await import("vue");
  return {
    default: defineComponent({
      render: () => h("div", { "data-test": "dashboard" }),
    }),
  };
});

const mount = (authenticated: boolean) =>
  mountWithDefaults(Component, {
    initialState: { session: { authenticated } },
  });

const shown = (subject: Awaited<ReturnType<typeof mount>>) =>
  ["legacy", "landing", "dashboard"].filter((name) =>
    subject.find(`[data-test='${name}']`).exists(),
  );

describe("HomePage", () => {
  beforeEach(() => {
    enabled = false;
  });

  it("keeps the current homepage while the redesign is off", async () => {
    expect(shown(await mount(false))).toEqual(["legacy"]);
    expect(shown(await mount(true))).toEqual(["legacy"]);
  });

  it("shows a visitor the landing page", async () => {
    enabled = true;

    expect(shown(await mount(false))).toEqual(["landing"]);
  });

  it("shows a signed-in pilot their dashboard", async () => {
    enabled = true;

    expect(shown(await mount(true))).toEqual(["dashboard"]);
  });
});
