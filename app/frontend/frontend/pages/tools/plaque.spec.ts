import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { defineRule } from "vee-validate";
import { max, required } from "@vee-validate/rules";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./plaque.vue";
import { type Model } from "@/services/fyApi";

const NOW = "2026-10-22T12:00:00Z";

const corsair = {
  id: "model-1",
  name: "Corsair",
  slug: "corsair",
  media: {},
  manufacturer: {
    name: "Drake Interplanetary",
    shortName: "Drake",
    shipyard: "Gemini Yards",
    slug: "drake",
    code: "DRAK",
    createdAt: NOW,
    updatedAt: NOW,
  },
} as unknown as Model;

const openModal = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({
    emit: (event: string, payload: unknown) => {
      if (event === "open-modal") openModal(payload);
    },
    on: () => () => undefined,
  }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useModel: (slug: { value: string }) => ({
    data: computed(() => (slug.value === "corsair" ? corsair : undefined)),
  }),
}));

const canShare = vi.fn(() => false);

vi.mock(
  "@/frontend/components/Vehicles/Plaque/download",
  async (importOriginal) => ({
    ...(await importOriginal<Record<string, unknown>>()),
    canSharePlaques: () => canShare(),
  }),
);

const mount = async ({
  model,
  signedIn = false,
}: { model?: string; signedIn?: boolean } = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/tools/plaque/",
        name: "plaque-tool",
        component: { template: "<div />" },
        meta: { title: "tools.plaque" },
      },
      { path: "/login", name: "login", component: { template: "<div />" } },
      { path: "/support", name: "support", component: { template: "<div />" } },
    ],
  });
  await router.push({ name: "plaque-tool", query: model ? { model } : {} });

  return mountWithDefaults<typeof Component>(Component, {
    plugins: [router],
    initialState: {
      session: signedIn
        ? {
            authenticated: true,
            currentUser: { username: "torlek", supporter: false },
          }
        : {},
    },
  });
};

describe("ToolsPlaquePage", () => {
  beforeAll(() => {
    defineRule("max", max);
    defineRule("required", required);
  });

  afterEach(() => {
    openModal.mockReset();
    canShare.mockReset();
    canShare.mockReturnValue(false);
  });

  it("asks for a ship before it draws a plaque", async () => {
    const wrapper = await mount();

    expect(wrapper.find('[data-test="plaque-tool-empty"]').exists()).toBe(true);
    expect(wrapper.find('[data-test="plaque-tool-preview"]').exists()).toBe(
      false,
    );
  });

  it("draws the plaque of the ship in the address, with its maker's lines", async () => {
    const wrapper = await mount({ model: "corsair" });

    const plaque = wrapper.find('[data-test="plaque-tool-preview"]');
    expect(plaque.find('[data-test="vehicle-plaque-name"]').text()).toBe(
      "Corsair",
    );
    expect(
      plaque.find('[data-test="vehicle-plaque-shipyard"]').text(),
    ).toContain("Gemini Yards");
    expect(plaque.text()).toContain("Drake Shipwrights");
  });

  it("writes the typed name and dedication onto the plaque", async () => {
    const wrapper = await mount({ model: "corsair" });

    await wrapper
      .find('[data-test="plaque-tool-name-input"] input')
      .setValue("Jolly Roger");
    await wrapper
      .find('[data-test="vehicle-plaque-dedication-input"] textarea')
      .setValue("Built rough");
    await flushPromises();

    const plaque = wrapper.find('[data-test="plaque-tool-preview"]');
    expect(plaque.find('[data-test="vehicle-plaque-name"]').text()).toBe(
      "Jolly Roger",
    );
    expect(
      plaque.find('[data-test="vehicle-plaque-dedication"]').text(),
    ).toContain("Built rough");
  });

  it("offers the share sheet only where the browser can share a picture", async () => {
    const withoutShare = await mount({ model: "corsair" });
    expect(withoutShare.find('[data-test="plaque-tool-share"]').exists()).toBe(
      false,
    );
    expect(
      withoutShare.find('[data-test="plaque-tool-download"]').exists(),
    ).toBe(true);

    canShare.mockReturnValue(true);
    const withShare = await mount({ model: "corsair" });
    expect(withShare.find('[data-test="plaque-tool-share"]').exists()).toBe(
      true,
    );
  });

  it("asks a visitor to sign in before saving to a hangar", async () => {
    const wrapper = await mount({ model: "corsair" });

    expect(wrapper.find('[data-test="plaque-tool-attach"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="plaque-tool-sign-in"]').exists()).toBe(
      true,
    );
  });

  it("hands a signed-in captain's plaque to the hangar picker", async () => {
    const wrapper = await mount({ model: "corsair", signedIn: true });

    await wrapper
      .find('[data-test="vehicle-plaque-dedication-input"] textarea')
      .setValue("Built rough");
    await wrapper.find('[data-test="plaque-tool-attach"]').trigger("click");
    await flushPromises();

    expect(openModal).toHaveBeenCalledWith(
      expect.objectContaining({
        props: expect.objectContaining({
          model: corsair,
          captain: "torlek",
          lines: expect.objectContaining({
            dedication: "Built rough",
            plaqueStyle: "brass",
          }),
        }),
      }),
    );
  });

  it("keeps a plaque without a dedication out of the hangar", async () => {
    const wrapper = await mount({ model: "corsair", signedIn: true });

    await wrapper.find('[data-test="plaque-tool-attach"]').trigger("click");
    await flushPromises();

    expect(openModal).not.toHaveBeenCalled();
  });
});
