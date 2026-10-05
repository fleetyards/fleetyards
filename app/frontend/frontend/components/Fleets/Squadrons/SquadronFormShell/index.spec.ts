import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { createMemoryHistory, createRouter } from "vue-router";
import { AxiosError, AxiosHeaders } from "axios";
import { createPinia } from "pinia";
import { defineRule } from "vee-validate";
import { max, min, required } from "@vee-validate/rules";

const createMutation = vi.fn();

vi.mock("@/services/fyApi", () => ({
  useCreateFleetSquadron: () => ({ mutateAsync: createMutation }),
  useUpdateFleetSquadron: () => ({ mutateAsync: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key, tExists: () => false }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn() }),
}));

import SquadronFormShell from "./index.vue";
import DetailsPage from "@/frontend/pages/fleets/[slug]/squadrons/form/details.vue";

const tabRoutes = [
  { path: "", name: "fleet-squadron-new", component: DetailsPage },
  {
    path: "other/",
    name: "fleet-squadron-new-other",
    component: { template: "<div />" },
  },
];

const buildRouter = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/fleets/:slug/squadrons/new/",
        component: { template: "<router-view v-bind='$attrs' />" },
        children: tabRoutes,
      },
      {
        path: "/fleets/:slug/squadrons/:squadron/",
        name: "fleet-squadron",
        component: { template: "<div />" },
      },
      {
        path: "/fleets/:slug/squadrons/",
        name: "fleet-squadrons",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push("/fleets/black-sun/squadrons/new/");
  return router;
};

const mountShell = async () => {
  const router = await buildRouter();
  const wrapper = mount(SquadronFormShell, {
    props: { fleet: { slug: "black-sun" } as never, tabRoutes },
    global: {
      plugins: [router, createPinia()],
      stubs: { TabNavViewItems: true },
    },
  });
  await flushPromises();
  return { router, wrapper };
};

const validationError = () =>
  new AxiosError("Unprocessable", "ERR_BAD_REQUEST", undefined, undefined, {
    status: 400,
    statusText: "Bad Request",
    headers: {},
    config: { headers: new AxiosHeaders() },
    data: {
      code: "validation_error",
      message: "Invalid",
      errors: [
        {
          attribute: "name",
          messages: [{ code: "taken", message: "has already been taken" }],
        },
      ],
    },
  });

describe("SquadronFormShell", () => {
  beforeAll(() => {
    defineRule("required", required);
    defineRule("min", min);
    defineRule("max", max);
  });

  beforeEach(() => {
    createMutation.mockReset();
  });

  it("keeps what was typed across a tab switch", async () => {
    const { router, wrapper } = await mountShell();

    await wrapper.find("input[name='name']").setValue("Rangers");
    await flushPromises();

    await router.push({ name: "fleet-squadron-new-other" });
    await flushPromises();
    await router.push({ name: "fleet-squadron-new" });
    await flushPromises();

    expect(
      (wrapper.find("input[name='name']").element as HTMLInputElement).value,
    ).toBe("Rangers");
  });

  it("keeps what was typed when the server rejects it", async () => {
    createMutation.mockRejectedValue(validationError());
    const { wrapper } = await mountShell();

    await wrapper.find("input[name='name']").setValue("Rangers");
    await wrapper
      .find("textarea[name='shortDescription']")
      .setValue("Ground team");
    await flushPromises();

    await wrapper.find("[data-test='submit-form']").trigger("click");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(createMutation).toHaveBeenCalled();
    expect(
      (wrapper.find("input[name='name']").element as HTMLInputElement).value,
    ).toBe("Rangers");
    expect(
      (
        wrapper.find("textarea[name='shortDescription']")
          .element as HTMLTextAreaElement
      ).value,
    ).toBe("Ground team");
  });

  it("keeps the other tab's values when the server rejects a save", async () => {
    createMutation.mockRejectedValue(validationError());
    const { router, wrapper } = await mountShell();

    await wrapper.find("input[name='name']").setValue("Rangers");
    await flushPromises();

    await router.push({ name: "fleet-squadron-new-other" });
    await flushPromises();

    await wrapper.find("form").trigger("submit");
    await flushPromises();

    await router.push({ name: "fleet-squadron-new" });
    await flushPromises();

    expect(createMutation.mock.calls[0][0].data.name).toBe("Rangers");
    expect(
      (wrapper.find("input[name='name']").element as HTMLInputElement).value,
    ).toBe("Rangers");
  });
});
