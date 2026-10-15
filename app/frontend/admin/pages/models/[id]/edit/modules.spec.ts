import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { createPinia } from "pinia";
import { createRouter, createMemoryHistory } from "vue-router";
import type { ModelExtended, ModelModule } from "@/services/fyAdminApi";

const modules = vi.hoisted(() => ({
  value: { items: [] as unknown[] },
}));

const updateModelModule = vi.hoisted(() => vi.fn(() => Promise.resolve({})));
const linkModelModule = vi.hoisted(() => vi.fn(() => Promise.resolve({})));

const mutation = vi.hoisted(
  () => (fn: (...args: unknown[]) => Promise<unknown>) => () => ({
    mutateAsync: fn,
    isPending: { value: false },
  }),
);

vi.mock("@/services/fyAdminApi", async () => {
  const { ref } = await import("vue");

  return {
    // A ref made when the page asks, holding whatever the test set before mounting.
    useListModelModules: () => ({
      data: ref(modules.value),
      isLoading: ref(false),
    }),
    useCreateModelModule: mutation(vi.fn(() => Promise.resolve({}))),
    useUpdateModelModule: mutation(updateModelModule),
    useDestroyModelModule: mutation(vi.fn(() => Promise.resolve({}))),
    useUnlinkModelModule: mutation(vi.fn(() => Promise.resolve({}))),
    useLinkModelModule: mutation(linkModelModule),
    getListModelModulesQueryKey: () => ["model-modules"],
  };
});

const displayAlert = vi.hoisted(() => vi.fn());

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert, displayConfirm: vi.fn() }),
}));

// The file input carries a 3D preview whose library does not load under the
// test runner.
vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: { name: "FormFileInput", template: "<div />" },
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, values?: Record<string, string>) =>
      values ? `${key} ${Object.values(values).join(" ")}` : key,
    toUEC: (value: number) => String(value),
  }),
}));

import ModulesPage from "./modules.vue";

const model = {
  id: "model-1",
  moduleSlots: ["hardpoint_front_module", "hardpoint_rear_module"],
} as unknown as ModelExtended;

const mod = (slot?: string) =>
  ({
    id: "module-1",
    name: "Front Cargo Module",
    moduleHardpoints: [
      { id: "mh-1", modelId: "model-1", slot },
      { id: "mh-2", modelId: "model-2", slot: "elsewhere" },
    ],
  }) as unknown as ModelModule;

const mountPage = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/models/:id/edit/modules/",
        name: "admin-model-edit-modules",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push("/models/model-1/edit/modules/");
  await router.isReady();

  // In a container: the page has several roots, and a wrapper only searches
  // the first of them.
  const wrapper = mount(
    {
      components: { ModulesPage },
      template: "<div><ModulesPage :model='model' /></div>",
      data: () => ({ model }),
    },
    {
      global: {
        plugins: [router, VueQueryPlugin, createPinia()],
        directives: { Tooltip: {} },
        stubs: {
          Heading: { template: "<div><slot /></div>" },
          BtnGroup: { template: "<div><slot /></div>" },
          Btn: { template: "<button><slot /></button>" },
          Paginator: true,
          LazyImage: true,
          FormFileInput: true,
          ManufacturerSelect: true,
          ProductionStatusSelect: true,
          FormInput: {
            props: ["modelValue", "name"],
            emits: ["update:modelValue"],
            template:
              "<input :name='name' :value='modelValue' @input=\"$emit('update:modelValue', $event.target.value)\" />",
          },
          InlineEditableList: {
            props: ["items"],
            emits: ["start-edit", "save-edit"],
            template:
              "<div><div v-for='item in items' :key='item.id'><slot name='display' :item='item' /><button data-test='start-edit' @click=\"$emit('start-edit', item)\" /><slot name='edit' :item='item' /><button data-test='save-edit' @click=\"$emit('save-edit')\" /></div></div>",
            methods: { finishEdit() {}, finishCreate() {} },
            data: () => ({ editingId: "module-1", creating: false }),
          },
        },
      },
    },
  );
  await flushPromises();
  return wrapper;
};

beforeEach(() => {
  updateModelModule.mockClear();
  linkModelModule.mockReset();
  linkModelModule.mockImplementation(() => Promise.resolve({}));
  displayAlert.mockClear();
});

describe("AdminModelEditModulesPage", () => {
  it("shows the module's slot on this hull, not on another", async () => {
    modules.value = { items: [mod("hardpoint_front_module")] };
    const wrapper = await mountPage();

    expect(wrapper.get("[data-test='model-module-slot']").text()).toBe(
      "hardpoint_front_module",
    );
  });

  it("lists the hull's module slots beside the slot field", async () => {
    modules.value = { items: [mod()] };
    const wrapper = await mountPage();

    expect(wrapper.get("[data-test='model-module-slots']").text()).toContain(
      "hardpoint_front_module, hardpoint_rear_module",
    );
  });

  it("saves a changed slot through the link, and clears it when emptied", async () => {
    modules.value = { items: [mod("hardpoint_front_module")] };
    const wrapper = await mountPage();

    await wrapper.get("[data-test='start-edit']").trigger("click");
    await wrapper
      .get("input[name='edit-slot']")
      .setValue("hardpoint_rear_module");
    await wrapper.get("[data-test='save-edit']").trigger("click");
    await flushPromises();

    expect(linkModelModule).toHaveBeenCalledWith({
      id: "module-1",
      data: { modelId: "model-1", slot: "hardpoint_rear_module" },
    });

    await wrapper.get("[data-test='start-edit']").trigger("click");
    await wrapper.get("input[name='edit-slot']").setValue("");
    await wrapper.get("[data-test='save-edit']").trigger("click");
    await flushPromises();

    expect(linkModelModule).toHaveBeenLastCalledWith({
      id: "module-1",
      data: { modelId: "model-1", slot: "" },
    });
  });

  it("says so and keeps the row open when the slot cannot be saved", async () => {
    modules.value = { items: [mod("hardpoint_front_module")] };
    linkModelModule.mockImplementation(() => Promise.reject(new Error("400")));
    const wrapper = await mountPage();

    await wrapper.get("[data-test='start-edit']").trigger("click");
    await wrapper
      .get("input[name='edit-slot']")
      .setValue("hardpoint_rear_module");
    await wrapper.get("[data-test='save-edit']").trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        text: expect.stringContaining("messages.modelModule.update.failure"),
      }),
    );
  });

  it("leaves the link alone when the slot did not change", async () => {
    modules.value = { items: [mod("hardpoint_front_module")] };
    const wrapper = await mountPage();

    await wrapper.get("[data-test='start-edit']").trigger("click");
    await wrapper.get("[data-test='save-edit']").trigger("click");
    await flushPromises();

    expect(updateModelModule).toHaveBeenCalled();
    expect(linkModelModule).not.toHaveBeenCalled();
  });
});
