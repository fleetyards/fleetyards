import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required } from "@vee-validate/rules";
import type { FleetRoleExtended } from "@/services/fyApi";
import Component from "./index.vue";

const updateRole = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useUpdateFleetRole: () => ({ mutateAsync: updateRole }),
  };
});

vi.mock("@tanstack/vue-query", async () => {
  const actual = await vi.importActual<Record<string, unknown>>(
    "@tanstack/vue-query",
  );

  return {
    ...actual,
    useQueryClient: () => ({ invalidateQueries: vi.fn() }),
  };
});

beforeAll(() => {
  defineRule("required", required);
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  updateRole.mockReset();
});

const role = (overrides: Partial<FleetRoleExtended> = {}) =>
  ({
    id: "member-id",
    name: "Member",
    slug: "member",
    permanent: false,
    defaultRole: true,
    ...overrides,
  }) as FleetRoleExtended;

const mount = async (subject: FleetRoleExtended) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleetSlug: "maru", role: subject },
  });

  return wrapper;
};

describe("FleetRoleModal", () => {
  it("saves the new name", async () => {
    updateRole.mockResolvedValue({});
    const subject = await mount(role());

    await subject
      .find('[data-test="fleet-role-name"] input')
      .setValue("Recruit");
    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(updateRole).toHaveBeenCalledWith({
      fleetSlug: "maru",
      id: "member-id",
      data: { name: "Recruit" },
    });
  });

  // Nothing to move the default to while a fleet cannot add roles.
  it("shows the default without offering to change it", async () => {
    const subject = await mount(role());
    const toggle = subject.find('[data-test="fleet-role-default"] input');

    expect((toggle.element as HTMLInputElement).checked).toBe(true);
    expect(toggle.attributes("disabled")).toBeDefined();
  });

  it("shows no default on the permanent Admin role", async () => {
    const subject = await mount(
      role({
        slug: "admin",
        name: "Admin",
        permanent: true,
        defaultRole: false,
      }),
    );

    expect(subject.find('[data-test="fleet-role-default"]').exists()).toBe(
      false,
    );
  });
});
