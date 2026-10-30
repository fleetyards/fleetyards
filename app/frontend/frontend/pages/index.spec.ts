import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import Component from "./index.vue";

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
  ["landing", "dashboard"].filter((name) =>
    subject.find(`[data-test='${name}']`).exists(),
  );

describe("HomePage", () => {
  it("shows a visitor the landing page", async () => {
    expect(shown(await mount(false))).toEqual(["landing"]);
  });

  it("shows a signed-in pilot the landing page too", async () => {
    expect(shown(await mount(true))).toEqual(["landing"]);
  });
});
