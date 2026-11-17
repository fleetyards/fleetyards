import { describe, it, expect, vi, beforeAll, beforeEach } from "vitest";
import { defineRule } from "vee-validate";
import { required } from "@vee-validate/rules";
import { mount, flushPromises } from "@vue/test-utils";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { createPinia } from "pinia";
import { createRouter, createMemoryHistory } from "vue-router";
import type { ModelModule } from "@/services/fyAdminApi";

const syncComponentViews = vi.hoisted(() =>
  vi.fn((_: { id: string }) => Promise.resolve({})),
);

vi.mock("@/services/fyAdminApi", () => ({
  useUpdateModelModule: () => ({
    mutateAsync: vi.fn(() => Promise.resolve({})),
    isPending: { value: false },
  }),
  useSyncComponentViews: () => ({
    mutateAsync: syncComponentViews,
    isPending: { value: false },
  }),
  getListModelModulesQueryKey: () => ["model-modules"],
  getModelModuleQueryKey: (id: string) => ["model-modules", id],
}));

const displayConfirm = vi.hoisted(() =>
  vi.fn(({ onConfirm }: { onConfirm: () => Promise<void> }) => onConfirm()),
);

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayAlert: vi.fn(),
    displaySuccess: vi.fn(),
    displayConfirm,
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

import Page from "./index.vue";

const buildModule = (componentId?: string | null) =>
  ({
    id: "module-1",
    name: "Cargo Module",
    scKey: "RSI_Galaxy_Module_Cargo",
    componentId,
    media: {},
  }) as unknown as ModelModule;

const mountPage = async (modelModule: ModelModule) => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/model-modules/:id/edit/",
        name: "admin-model-module-edit",
        component: { template: "<div />" },
      },
      {
        path: "/components/:id/edit/",
        name: "admin-component-edit",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push("/model-modules/module-1/edit/");
  await router.isReady();

  // In a container: the page has several roots, and a wrapper only searches
  // the first of them.
  const wrapper = mount(
    {
      components: { Page },
      template: "<div><Page :model-module='modelModule' /></div>",
      data: () => ({ modelModule }),
    },
    {
      global: {
        plugins: [router, VueQueryPlugin, createPinia()],
        stubs: {
          Heading: { template: "<div><slot /></div>" },
          Btn: {
            props: ["to"],
            emits: ["click"],
            template:
              "<button :data-to='to ? JSON.stringify(to) : undefined' @click=\"$emit('click')\"><slot /></button>",
          },
          FormInput: true,
          FormTextarea: true,
          FormToggle: true,
          FormFileInput: true,
          FormActions: true,
          ManufacturerSelect: true,
          ProductionStatusSelect: true,
        },
      },
    },
  );
  await flushPromises();

  return wrapper;
};

describe("AdminModelModuleEditIndexPage", () => {
  beforeAll(() => {
    defineRule("required", required);
  });

  beforeEach(() => {
    syncComponentViews.mockClear();
  });

  it("links to the module's part in the game files", async () => {
    const wrapper = await mountPage(buildModule("component-1"));

    const link = wrapper.get("[data-test='model-module-component-link']");
    expect(JSON.parse(link.attributes("data-to") ?? "{}")).toEqual({
      name: "admin-component-edit",
      params: { id: "component-1" },
    });
  });

  it("syncs the views of the module's part", async () => {
    const wrapper = await mountPage(buildModule("component-1"));

    await wrapper.get("[data-test='model-module-sync-views']").trigger("click");
    await flushPromises();

    expect(syncComponentViews).toHaveBeenCalledWith({ id: "component-1" });
  });

  it("offers neither without a part", async () => {
    const wrapper = await mountPage(buildModule(null));

    expect(
      wrapper.find("[data-test='model-module-component-actions']").exists(),
    ).toBe(false);
  });
});
