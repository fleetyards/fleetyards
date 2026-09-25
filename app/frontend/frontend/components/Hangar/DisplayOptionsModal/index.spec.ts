import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

const update = vi.fn((_variables: unknown) => Promise.resolve());
const displayAlert = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useUpdateProfile: () => ({ mutateAsync: update }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({ currentUser: { hangarDefaultSort: "rank asc" } }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert }),
}));

const defaultSortSelect = async () =>
  (await mountWithDefaults(Component))
    .findAllComponents({ name: "BaseSelect" })
    .find((select) => select.props("name") === "hangarDefaultSort")!;

describe("HangarDisplayOptionsModal", () => {
  beforeEach(() => {
    update.mockReset();
    update.mockImplementation(() => Promise.resolve());
    displayAlert.mockClear();
  });

  it("shows the account's default order", async () => {
    expect((await defaultSortSelect()).props("modelValue")).toBe("rank asc");
  });

  it("stores a new default order on the account as it is picked", async () => {
    const select = await defaultSortSelect();

    select.vm.$emit("update:modelValue", null);
    await flushPromises();

    expect(update).toHaveBeenCalledWith({ data: { hangarDefaultSort: null } });
    expect(select.props("modelValue")).toBeNull();
  });

  it("goes back to the stored order when the save fails", async () => {
    update.mockImplementation(() => Promise.reject(new Error("offline")));
    const select = await defaultSortSelect();

    select.vm.$emit("update:modelValue", "name desc");
    await flushPromises();

    expect(select.props("modelValue")).toBe("rank asc");
    expect(displayAlert).toHaveBeenCalledTimes(1);
  });
});
