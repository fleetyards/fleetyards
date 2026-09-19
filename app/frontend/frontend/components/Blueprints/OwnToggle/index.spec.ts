import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Blueprint } from "@/services/fyApi";

const own = vi.fn().mockResolvedValue(undefined);
const unown = vi.fn().mockResolvedValue(undefined);
const displayWarning = vi.fn();

const authenticated = { value: true };

vi.mock("@/services/fyApi", () => ({
  useOwnBlueprint: () => ({ mutateAsync: own }),
  useUnownBlueprint: () => ({ mutateAsync: unown }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get isAuthenticated() {
      return authenticated.value;
    },
  }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayWarning, displayAlert: vi.fn() }),
}));

const Component = (await import("./index.vue")).default;

const blueprint = (attrs: Partial<Blueprint> = {}) =>
  ({
    id: "id",
    name: "10-Series Greatsword Cannon",
    slug: "kbar-ballisticcannon-s2",
    scKey: "bp_craft_kbar_ballisticcannon_s2",
    scRef: "ref",
    retired: false,
    owned: false,
    sourceUnknown: false,
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Blueprint;

const mount = (attrs: Partial<Blueprint> = {}) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { blueprint: blueprint(attrs) },
  });

describe("BlueprintOwnToggle", () => {
  beforeEach(() => {
    authenticated.value = true;
    own.mockClear();
    unown.mockClear();
    displayWarning.mockClear();
  });

  it("marks an unheld recipe", async () => {
    const wrapper = await mount();

    await wrapper.find("[data-test='blueprint-own-toggle']").trigger("click");

    expect(own).toHaveBeenCalledWith({ slug: "kbar-ballisticcannon-s2" });
    expect(unown).not.toHaveBeenCalled();
  });

  it("unmarks a held one", async () => {
    const wrapper = await mount({ owned: true });

    await wrapper.find("[data-test='blueprint-own-toggle']").trigger("click");

    expect(unown).toHaveBeenCalledWith({ slug: "kbar-ballisticcannon-s2" });
    expect(own).not.toHaveBeenCalled();
  });

  it("says which state it is in", async () => {
    const held = await mount({ owned: true });
    const unheld = await mount();

    expect(held.find(".fa-bookmark").classes()).toContain("fa");
    expect(unheld.find(".fa-bookmark").classes()).toContain("fa-light");
  });

  // The catalogue is public, so this is the state most readers are in. It asks
  // them to sign in rather than firing a request that can only be a 401.
  it("asks an anonymous reader to sign in instead of calling the API", async () => {
    authenticated.value = false;

    const wrapper = await mount();

    await wrapper.find("[data-test='blueprint-own-toggle']").trigger("click");

    expect(own).not.toHaveBeenCalled();
    expect(displayWarning).toHaveBeenCalled();
  });
});
