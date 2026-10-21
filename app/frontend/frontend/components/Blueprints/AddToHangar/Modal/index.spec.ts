import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Blueprint } from "@/services/fyApi";

const calls: string[] = [];
const mutation = (name: string) => () => ({
  mutateAsync: vi.fn(async () => {
    calls.push(name);
  }),
});

const emit = vi.fn();

vi.mock("@/services/fyApi", () => ({
  useOwnBlueprint: mutation("own"),
  useUnownBlueprint: mutation("unown"),
  useWantBlueprint: mutation("want"),
  useUnwantBlueprint: mutation("unwant"),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
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

const choiceKeys = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper
    .findAll(".add-to-hangar-choice")
    .map((choice) => choice.attributes("data-test"));

describe("BlueprintAddToHangarModal", () => {
  beforeEach(() => {
    calls.length = 0;
    emit.mockClear();
  });

  it("offers owning or wanting an unmarked recipe", async () => {
    const wrapper = await mount();

    expect(choiceKeys(wrapper)).toEqual([
      "blueprint-add-to-hangar-own",
      "blueprint-add-to-hangar-want",
    ]);
  });

  it("offers owning or dropping a wanted recipe", async () => {
    const wrapper = await mount({ wanted: true });

    expect(choiceKeys(wrapper)).toEqual([
      "blueprint-add-to-hangar-own",
      "blueprint-add-to-hangar-unwant",
    ]);
  });

  it("offers moving or dropping a held recipe", async () => {
    const wrapper = await mount({ owned: true });

    expect(choiceKeys(wrapper)).toEqual([
      "blueprint-add-to-hangar-move",
      "blueprint-add-to-hangar-unown",
    ]);
  });

  it("puts a recipe on the wishlist and closes", async () => {
    const wrapper = await mount();

    await wrapper
      .find("[data-test='blueprint-add-to-hangar-want']")
      .trigger("click");
    await flushPromises();

    expect(calls).toEqual(["want"]);
    expect(emit).toHaveBeenCalledWith("close-modal");
  });

  // `want` keeps a held recipe held, so the held mark has to go first.
  it("moves a held recipe by dropping the mark before wanting it", async () => {
    const wrapper = await mount({ owned: true });

    await wrapper
      .find("[data-test='blueprint-add-to-hangar-move']")
      .trigger("click");
    await flushPromises();

    expect(calls).toEqual(["unown", "want"]);
  });
});
