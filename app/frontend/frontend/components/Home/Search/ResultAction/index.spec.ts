import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  blueprint,
  commodity,
  model,
  type SearchResult,
} from "@/services/fyApi";

const emit = vi.fn();
const displayAlert = vi.fn();
const authenticated = { value: true };

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get isAuthenticated() {
      return authenticated.value;
    },
  }),
}));

vi.mock("@/frontend/stores/hangar", () => ({
  useHangarStore: () => ({ ships: ["held-ship"] }),
}));

vi.mock("@/frontend/stores/wishlist", () => ({
  useWishlistStore: () => ({ ships: [] }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  blueprint: vi.fn(),
  commodity: vi.fn(),
  model: vi.fn(),
}));

const Component = (await import("./index.vue")).default;

const mount = (result: Partial<SearchResult>) =>
  mountWithDefaults<typeof Component>(Component, {
    props: {
      result: { name: "Item", slug: "item", ...result } as SearchResult,
    },
  });

type Wrapper = Awaited<ReturnType<typeof mount>>;

const press = async (wrapper: Wrapper) => {
  await wrapper.find("[data-test='home-search-action']").trigger("click");
  await flushPromises();
};

describe("HomeSearchResultAction", () => {
  beforeEach(() => {
    authenticated.value = true;
    emit.mockClear();
    displayAlert.mockClear();
    vi.mocked(blueprint).mockReset();
    vi.mocked(commodity).mockReset();
    vi.mocked(model).mockReset();
  });

  it("offers nothing to a visitor", async () => {
    authenticated.value = false;
    const wrapper = await mount({ type: "Model" });

    expect(wrapper.find("[data-test='home-search-action']").exists()).toBe(
      false,
    );
  });

  it.each(["GameMission", "Location"])(
    "offers nothing on a %s",
    async (type) => {
      const wrapper = await mount({ type });

      expect(wrapper.find("[data-test='home-search-action']").exists()).toBe(
        false,
      );
    },
  );

  it("opens the blueprint's own modal with its full record", async () => {
    const record = { id: "id", owned: false };
    vi.mocked(blueprint).mockResolvedValue(record as never);
    const wrapper = await mount({ type: "Blueprint" });

    await press(wrapper);

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ props: { blueprint: record } }),
    );
    expect(wrapper.emitted("opened")).toHaveLength(1);
  });

  it("files a commodity through the inventory modal", async () => {
    vi.mocked(commodity).mockResolvedValue({
      id: "id",
      name: "Ore",
      counted: true,
      retired: false,
    } as never);
    const wrapper = await mount({ type: "Commodity" });

    await press(wrapper);

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({
        props: {
          item: expect.objectContaining({
            name: "Ore",
            item: expect.objectContaining({ type: "Commodity", id: "id" }),
          }),
        },
      }),
    );
  });

  it("hands back a ship no player can own instead of opening the modal", async () => {
    vi.mocked(model).mockResolvedValue({ playerOwnable: false } as never);
    const wrapper = await mount({ type: "Model" });

    await press(wrapper);

    expect(emit).not.toHaveBeenCalled();
    expect(wrapper.emitted("unavailable")).toHaveLength(1);
  });

  it("hands back a retired record instead of opening the modal", async () => {
    vi.mocked(commodity).mockResolvedValue({ retired: true } as never);
    const wrapper = await mount({ type: "Commodity" });

    await press(wrapper);

    expect(emit).not.toHaveBeenCalled();
    expect(wrapper.emitted("unavailable")).toHaveLength(1);
  });

  it("marks a ship already in the hangar", async () => {
    const wrapper = await mount({ type: "Model", slug: "held-ship" });

    expect(wrapper.find(".fa-bookmark.fa").exists()).toBe(true);
  });

  it("says so when the record cannot be fetched", async () => {
    vi.mocked(blueprint).mockRejectedValue(new Error("offline"));
    const wrapper = await mount({ type: "Blueprint" });

    await press(wrapper);

    expect(displayAlert).toHaveBeenCalled();
    expect(emit).not.toHaveBeenCalled();
  });
});
