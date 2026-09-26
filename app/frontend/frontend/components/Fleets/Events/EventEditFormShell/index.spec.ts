import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";

const updateMutation = vi.fn();
const replace = vi.fn(() => Promise.resolve());
const emit = vi.fn();

const route = vi.hoisted(() => ({
  name: "fleet-event-edit-schedule",
  params: { slug: "black-sun", event: "a1b2c3d4-old-title" },
  query: { occurrence: "2026-10-01" },
}));

vi.mock("@/services/fyApi", () => ({
  useUpdateFleetEvent: () => ({ mutateAsync: updateMutation }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: vi.fn() }),
}));

vi.mock("vue-router", () => ({
  useRoute: () => route,
  useRouter: () => ({ push: vi.fn(), replace }),
}));

import EventEditFormShell from "./index.vue";

const mountShell = () =>
  mount(EventEditFormShell, {
    props: {
      fleet: { slug: "black-sun" } as never,
      event: { slug: "a1b2c3d4-old-title" } as never,
      handleSubmit: (cb: (values: never, ctx: never) => unknown) => () =>
        Promise.resolve(cb({ title: "New title" } as never, {} as never)),
      meta: { dirty: true, touched: true },
    },
    global: { stubs: { FormActions: true } },
  });

describe("EventEditFormShell", () => {
  beforeEach(() => {
    updateMutation.mockReset();
    replace.mockClear();
    emit.mockClear();
  });

  it("moves to the new slug when a rename changes it", async () => {
    updateMutation.mockResolvedValue({ slug: "a1b2c3d4-new-title" });

    await mountShell().find("form").trigger("submit");
    await flushPromises();

    expect(replace).toHaveBeenCalledWith({
      name: "fleet-event-edit-schedule",
      params: { slug: "black-sun", event: "a1b2c3d4-new-title" },
      query: { occurrence: "2026-10-01" },
    });
    expect(emit).toHaveBeenCalledWith("fleet-event-updated");
  });

  it("stays put when the slug is unchanged", async () => {
    updateMutation.mockResolvedValue({ slug: "a1b2c3d4-old-title" });

    await mountShell().find("form").trigger("submit");
    await flushPromises();

    expect(replace).not.toHaveBeenCalled();
    expect(emit).toHaveBeenCalledWith("fleet-event-updated");
  });
});
