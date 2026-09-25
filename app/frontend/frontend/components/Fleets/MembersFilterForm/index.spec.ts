import { mount, flushPromises } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { VueQueryPlugin } from "@tanstack/vue-query";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const { route, replace } = vi.hoisted(() => ({
  route: {
    name: "fleet-members",
    params: {},
    query: {} as Record<string, unknown>,
  },
  replace: vi.fn((_to: { query: Record<string, unknown> }) =>
    Promise.resolve(),
  ),
}));

vi.mock("vue-router", () => ({
  useRoute: () => route,
  useRouter: () => ({ replace }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key, tExists: () => false }),
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

describe("FleetMembersFilterForm", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.useFakeTimers();
    replace.mockClear();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("shows the search from the URL", async () => {
    route.query = { searchCont: "wing" };
    const wrapper = mountForm();
    await flushPromises();

    expect(
      (wrapper.find("input#member-search").element as HTMLInputElement).value,
    ).toBe("wing");
  });

  // A link saved before the combined search still carries `usernameCont`,
  // which the API keeps accepting -- left in the URL it would narrow every
  // search typed into the box.
  it("folds a legacy usernameCont into the search", async () => {
    route.query = { usernameCont: "alice" };
    const wrapper = mountForm();
    await flushPromises();

    const input = wrapper.find("input#member-search");
    expect((input.element as HTMLInputElement).value).toBe("alice");

    await input.setValue("wingman");
    vi.advanceTimersByTime(400);

    expect(replace).toHaveBeenCalled();
    const { query } = replace.mock.lastCall![0];
    expect(query.searchCont).toBe("wingman");
    expect(query).not.toHaveProperty("usernameCont");
  });
});
