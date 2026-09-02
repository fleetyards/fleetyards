import { ref } from "vue";
import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import type { AdminUserResourceAccessEnum } from "@/services/fyAdminApi";
import Component from "./index.vue";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/services/fyAdminApi", () => ({
  useResourceAccessCatalog: () => ({
    data: ref([
      { key: "ship_data", privileges: ["models", "vehicles"] },
      { key: "system", privileges: ["admins"] },
    ]),
  }),
}));

const mountWith = (modelValue: AdminUserResourceAccessEnum[] = []) =>
  mount(Component, { props: { modelValue } });

describe("AdminUsersResourceAccess", () => {
  it("renders a checkbox per privilege of every group", () => {
    const wrapper = mountWith();

    expect(wrapper.findAll(".resource-access-group")).toHaveLength(2);
    expect(wrapper.findAll("input[type=checkbox]")).toHaveLength(3);
  });

  it("checks the privileges the admin already has", () => {
    const wrapper = mountWith(["vehicles"]);

    const checked = wrapper
      .findAll("input[type=checkbox]")
      .map((input) => (input.element as HTMLInputElement).checked);

    expect(checked).toEqual([false, true, false]);
  });

  it("adds a privilege that gets checked", async () => {
    const wrapper = mountWith(["vehicles"]);

    await wrapper.findAll("input[type=checkbox]")[0].trigger("change");

    expect(wrapper.emitted("update:modelValue")).toEqual([
      [["vehicles", "models"]],
    ]);
  });

  it("removes a privilege that gets unchecked", async () => {
    const wrapper = mountWith(["models", "vehicles"]);

    await wrapper.findAll("input[type=checkbox]")[1].trigger("change");

    expect(wrapper.emitted("update:modelValue")).toEqual([[["models"]]]);
  });
});
