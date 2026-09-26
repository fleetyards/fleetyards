import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { createMemoryHistory, createRouter, type Router } from "vue-router";

const updateMutation = vi.fn();
const emittedOn = vi.hoisted(() => ({ value: [] as string[] }));
const currentRouter = vi.hoisted(() => ({ value: undefined as unknown }));

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

// Records the event slug in the URL at the moment the layout is told to
// refetch, since that refetch reads its slug from the route.
vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({
    emit: () => {
      const router = currentRouter.value as Router;
      emittedOn.value.push(router.currentRoute.value.params.event as string);
    },
    on: vi.fn(),
  }),
}));

import EventEditFormShell from "./index.vue";

const OLD_SLUG = "a1b2c3d4-old-title";
const START = `/fleets/black-sun/events/${OLD_SLUG}/edit/schedule?occurrence=2026-10-01#repeat`;

const buildRouter = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: "/fleets/:slug/events/:event/edit/schedule",
        name: "fleet-event-edit-schedule",
        component: { template: "<div />" },
      },
      {
        path: "/fleets/:slug/events/:event",
        name: "fleet-event",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push(START);
  currentRouter.value = router;
  return router;
};

const mountShell = (router: Router) =>
  mount(EventEditFormShell, {
    props: {
      fleet: { slug: "black-sun" } as never,
      event: { slug: OLD_SLUG } as never,
      handleSubmit: (cb: (values: never, ctx: never) => unknown) => () =>
        Promise.resolve(cb({ title: "New title" } as never, {} as never)),
      meta: { dirty: true, touched: true },
    },
    global: { plugins: [router], stubs: { FormActions: true } },
  });

describe("EventEditFormShell", () => {
  beforeEach(() => {
    updateMutation.mockReset();
    emittedOn.value = [];
  });

  it("moves to the new slug before the page refetches", async () => {
    updateMutation.mockResolvedValue({ slug: "a1b2c3d4-new-title" });
    const router = await buildRouter();

    await mountShell(router).find("form").trigger("submit");
    await flushPromises();

    expect(router.currentRoute.value.fullPath).toBe(
      "/fleets/black-sun/events/a1b2c3d4-new-title/edit/schedule?occurrence=2026-10-01#repeat",
    );
    expect(emittedOn.value).toEqual(["a1b2c3d4-new-title"]);
  });

  it("stays put when the slug is unchanged", async () => {
    updateMutation.mockResolvedValue({ slug: OLD_SLUG });
    const router = await buildRouter();

    await mountShell(router).find("form").trigger("submit");
    await flushPromises();

    expect(router.currentRoute.value.fullPath).toBe(START);
    expect(emittedOn.value).toEqual([OLD_SLUG]);
  });
});
