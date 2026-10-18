import { mount, flushPromises } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";

const { route, replace, push } = vi.hoisted(() => ({
  route: {
    name: "components",
    params: {},
    query: {} as Record<string, unknown>,
  },
  replace: vi.fn((_to: { query: Record<string, unknown> }) =>
    Promise.resolve(),
  ),
  push: vi.fn((_to: { query: Record<string, unknown> }) => Promise.resolve()),
}));

vi.mock("vue-router", () => ({
  useRoute: () => route,
  useRouter: () => ({ replace, push }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key, tExists: () => false }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useComponentCategoriesFilters: () => ({ data: ref([]) }),
  useComponentSubTypesFilters: () => ({ data: ref([]) }),
}));

vi.mock("@/frontend/components/base/ManufacturerSelect/index.vue", () => ({
  default: { name: "ManufacturerSelect", render: () => null },
}));

import Component from "./index.vue";

const mountForm = () =>
  mount(Component, {
    global: {
      plugins: [VueQueryPlugin],
      stubs: { teleport: true },
      directives: { Tooltip: {} },
    },
  });

describe("ComponentsFilterForm", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.useFakeTimers();
    replace.mockClear();
    push.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  // A link saved before the alias search still carries `nameCont`, which the
  // API keeps accepting -- left in the URL it would narrow every search typed
  // into the box, and miss what players call a part.
  it("folds a legacy nameCont into the alias search", async () => {
    route.query = { nameCont: "ore pod" };
    const wrapper = mountForm();
    await flushPromises();

    const input = wrapper.find("input[name='search']");
    expect((input.element as HTMLInputElement).value).toBe("ore pod");

    vi.advanceTimersByTime(2000);
    push.mockClear();
    replace.mockClear();

    await input.setValue("mining bag");
    vi.advanceTimersByTime(400);

    const calls = [...push.mock.calls, ...replace.mock.calls];
    expect(calls.length).toBeGreaterThan(0);
    const { query } = calls[calls.length - 1][0];
    expect(query.searchNameCont).toBe("mining bag");
    expect(query).not.toHaveProperty("nameCont");
  });
});
