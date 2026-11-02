import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { type Outfit } from "@/services/fyApi";

const NOW = "2026-11-02T12:00:00Z";

const heavy = {
  id: "outfit-1",
  name: "Heavy",
  items: [{ slot: "torso", equipment: { id: "core", slug: "adp-core" } }],
  createdAt: NOW,
  updatedAt: NOW,
} as unknown as Outfit;

const outfits = ref<Outfit[]>([heavy]);
const create = vi.fn(() => Promise.resolve({ ...heavy, id: "outfit-2" }));
const update = vi.fn(() => Promise.resolve(heavy));
const destroy = vi.fn(() => Promise.resolve({ success: true }));

const mutation = (mutateAsync: unknown) => ({
  mutateAsync,
  isPending: ref(false),
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useOutfits: () => ({ data: outfits, isLoading: ref(false) }),
  useCreateOutfit: () => mutation(create),
  useUpdateOutfit: () => mutation(update),
  useDestroyOutfit: () => mutation(destroy),
}));

const { default: Outfits } = await import("./index.vue");

const mount = (props: Record<string, unknown>, signedIn = true) =>
  mountWithDefaults<typeof Outfits>(Outfits, {
    props: {
      selection: { torso: "adp-core" },
      items: [{ slot: "torso", equipmentId: "core" }],
      ...props,
    } as never,
    initialState: {
      session: signedIn
        ? { authenticated: true, currentUser: { username: "torlek" } }
        : {},
    },
  });

describe("DressingRoomOutfits", () => {
  beforeEach(() => {
    create.mockClear();
    update.mockClear();
  });

  it("asks to sign in before it offers to save", async () => {
    const wrapper = await mount({}, false);

    expect(wrapper.text()).toContain("Sign in to save outfits.");
    expect(wrapper.find('[data-test="dressing-room-save-new"]').exists()).toBe(
      false,
    );
  });

  it("saves the selection as a new outfit and makes it the active one", async () => {
    const wrapper = await mount({});

    await wrapper
      .find('input[name="dressing-room-outfit-name"]')
      .setValue("Recon");
    await wrapper
      .find(
        '[data-test="dressing-room-save-new"] button, [data-test="dressing-room-save-new"]',
      )
      .trigger("click");
    await flushPromises();

    expect(create).toHaveBeenCalledWith({
      data: { name: "Recon", items: [{ slot: "torso", equipmentId: "core" }] },
    });
    expect(wrapper.emitted("active")).toEqual([["outfit-2"]]);
  });

  it("will not save a second outfit under a name already taken", async () => {
    const wrapper = await mount({});

    await wrapper
      .find('input[name="dressing-room-outfit-name"]')
      .setValue("Heavy");

    expect(wrapper.text()).toContain(
      "You already have an outfit with this name.",
    );
  });

  it("offers to save changes only once the active outfit differs", async () => {
    const wrapper = await mount({ activeId: "outfit-1" });
    const saveChanges = () =>
      wrapper.find('[data-test="dressing-room-save-changes"]');

    expect(saveChanges().attributes("disabled")).toBeDefined();

    await wrapper.setProps({
      selection: { torso: "adp-core", legs: "adp-legs" },
    } as never);

    expect(saveChanges().attributes("disabled")).toBeUndefined();
  });

  it("loads an outfit when it is picked from the list", async () => {
    const wrapper = await mount({});

    await wrapper
      .find('[data-test="dressing-room-outfit-outfit-1"]')
      .trigger("click");

    expect(wrapper.emitted("load")).toEqual([[heavy]]);
  });
});
