import { describe, it, expect, vi, beforeAll, beforeEach } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { defineRule } from "vee-validate";
import { regex } from "@vee-validate/rules";
import type { Location } from "@/services/fyAdminApi";

const location = vi.hoisted(() => ({
  value: undefined as Location | undefined,
}));

vi.mock("@/services/fyAdminApi", () => ({
  useLocation: () => ({
    data: location,
    isLoading: ref(false),
    isFetching: ref(false),
    isError: ref(false),
  }),
  useUpdateLocation: () => ({ mutateAsync: vi.fn() }),
  getLocationQueryKey: () => ["location"],
  getLocationsQueryKey: () => ["locations"],
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/admin/composables/useFormFeedback", () => ({
  useFormFeedback: () => ({ updated: vi.fn(), failed: vi.fn() }),
}));

vi.mock("@/shared/composables/useMetaInfo", () => ({
  useMetaInfo: () => ({ updateMetaInfo: vi.fn() }),
}));

// The real field pulls in the holo viewer, and three.js does not resolve
// under vitest.
vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: {
    name: "FormFileInput",
    props: ["modelValue", "file"],
    emits: ["update:modelValue", "uploaded"],
    template: "<div />",
  },
}));

vi.mock("@/frontend/components/Locations/Globe/index.vue", () => ({
  default: { name: "LocationGlobe", template: "<div />" },
}));

import EditPage from "./edit.vue";

const record = (overrides: Partial<Location> = {}) =>
  ({
    id: "levski",
    name: "Levski",
    slug: "levski",
    scKey: "Nyx_Levski",
    kind: "city",
    color: null,
    drawnColor: null,
    ...overrides,
  }) as unknown as Location;

const mountPage = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/locations/:id/edit",
        name: "admin-location-edit",
        component: { template: "<div />" },
      },
      {
        path: "/locations/:id",
        name: "admin-location",
        component: { template: "<div />" },
      },
      {
        path: "/locations",
        name: "admin-locations",
        component: { template: "<div />" },
      },
    ],
  });

  await router.push({ name: "admin-location-edit", params: { id: "levski" } });
  await router.isReady();

  return mount(EditPage, {
    global: {
      plugins: [router, VueQueryPlugin],
      stubs: {
        AsyncData: { template: "<div><slot name='resolved' /></div>" },
        BreadCrumbs: true,
        Heading: { template: "<div><slot /></div>" },
        FormInput: true,
        FormActions: true,
      },
    },
  });
};

const header = (wrapper: Awaited<ReturnType<typeof mountPage>>) =>
  wrapper.find('[data-test="location-header-preview"]');

describe("AdminLocationEditPage header preview", () => {
  beforeAll(() => {
    defineRule("regex", regex);
    vi.stubGlobal("URL", {
      ...URL,
      createObjectURL: () => "blob:pending",
      revokeObjectURL: vi.fn(),
    });
  });

  beforeEach(() => {
    location.value = record({
      image: { url: "https://example.test/saved.webp" },
    } as Partial<Location>);
  });

  it("shows the saved picture", async () => {
    const wrapper = await mountPage();

    expect(header(wrapper).attributes("src")).toBe(
      "https://example.test/saved.webp",
    );
  });

  it("shows nothing once the picture is cleared", async () => {
    const wrapper = await mountPage();

    wrapper
      .findComponent({ name: "FormFileInput" })
      .vm.$emit("update:modelValue", null);
    await flushPromises();

    expect(header(wrapper).exists()).toBe(false);
  });

  it("shows a picture uploaded but not yet saved", async () => {
    const wrapper = await mountPage();
    const input = wrapper.findComponent({ name: "FormFileInput" });

    input.vm.$emit("uploaded", new File(["x"], "new.png"));
    input.vm.$emit("update:modelValue", "signed-id");
    await flushPromises();

    expect(header(wrapper).attributes("src")).toBe("blob:pending");
  });
});
