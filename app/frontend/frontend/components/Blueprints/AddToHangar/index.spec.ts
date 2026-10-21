import { beforeEach, describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Blueprint } from "@/services/fyApi";

const emit = vi.fn();
const displayWarning = vi.fn();

const authenticated = { value: true };

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get isAuthenticated() {
      return authenticated.value;
    },
  }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayWarning }),
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
    wanted: false,
    sourceUnknown: false,
    createdAt: "2026-01-01",
    updatedAt: "2026-01-01",
    ...attrs,
  }) as Blueprint;

const mount = (attrs: Partial<Blueprint> = {}) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { blueprint: blueprint(attrs) },
  });

describe("BlueprintAddToHangar", () => {
  beforeEach(() => {
    authenticated.value = true;
    emit.mockClear();
    displayWarning.mockClear();
  });

  it("asks which mark to set", async () => {
    const wrapper = await mount();

    await wrapper
      .find("[data-test='blueprint-add-to-hangar']")
      .trigger("click");

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: {
          blueprint: expect.objectContaining({
            slug: "kbar-ballisticcannon-s2",
          }),
        },
      }),
    );
  });

  it("is solid when held or wanted", async () => {
    const held = await mount({ owned: true });
    const wanted = await mount({ wanted: true });
    const neither = await mount();

    expect(held.find(".fa-bookmark").classes()).toContain("fa");
    expect(wanted.find(".fa-bookmark").classes()).toContain("fa");
    expect(neither.find(".fa-bookmark").classes()).toContain("fa-light");
  });

  // The catalogue is public, so this is the state most readers are in.
  it("asks an anonymous reader to sign in instead of opening the modal", async () => {
    authenticated.value = false;

    const wrapper = await mount();

    await wrapper
      .find("[data-test='blueprint-add-to-hangar']")
      .trigger("click");

    expect(emit).not.toHaveBeenCalled();
    expect(displayWarning).toHaveBeenCalled();
  });
});
