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

  // A choice superseded while the one before it was saving never goes out, so
  // the account cannot end up on the order picked first.
  it("saves only the latest of two quick choices", async () => {
    let finishFirst: () => void = () => undefined;
    update.mockImplementationOnce(
      () => new Promise<void>((resolve) => (finishFirst = resolve)),
    );
    const select = await defaultSortSelect();

    select.vm.$emit("update:modelValue", "name asc");
    await flushPromises();
    select.vm.$emit("update:modelValue", "name desc");
    select.vm.$emit("update:modelValue", "modelPrice desc");
    finishFirst();
    await flushPromises();

    expect(update.mock.calls.map(([call]) => call)).toEqual([
      { data: { hangarDefaultSort: "name asc" } },
      { data: { hangarDefaultSort: "modelPrice desc" } },
    ]);
    expect(select.props("modelValue")).toBe("modelPrice desc");
  });
});
