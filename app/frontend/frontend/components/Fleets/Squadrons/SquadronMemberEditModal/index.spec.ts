import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import type { FleetSquadronRole } from "@/services/fyApi";
import Component from "./index.vue";

const updateMember = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useUpdateFleetSquadronMember: () => ({ mutateAsync: updateMember }),
  };
});

const rank = (key: string, position: number) =>
  ({ id: key, key, name: key, position }) as FleetSquadronRole;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  updateMember.mockReset();
});

const mount = async (props: Record<string, unknown>) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleetSlug: "maru",
      squadronSlug: "mining",
      username: "hauler",
      membershipCreatedAt: "2024-05-14T10:00:00Z",
      roleId: "member",
      ...props,
    },
  });

  return wrapper;
};

const submit = async (subject: VueWrapper) => {
  await subject.find("form").trigger("submit");
  await flushPromises();
};

describe("SquadronMemberEditModal", () => {
  it("hides the rank for an editor who may not change it", async () => {
    const subject = await mount({ rankOptions: [] });

    expect(subject.find('[data-test="squadron-member-rank"]').exists()).toBe(
      false,
    );
  });

  it("sends only the join date when the rank is not the editor's", async () => {
    const subject = await mount({ rankOptions: [] });

    await submit(subject);

    expect(updateMember).toHaveBeenCalledWith(
      expect.objectContaining({ data: { createdAt: "2024-05-14" } }),
    );
  });

  // Stepping down on one's own row: the rank is theirs to change, the date is
  // not, and a date in the payload would get the whole update refused.
  it("leaves the date out when it is not the editor's", async () => {
    const subject = await mount({
      rankOptions: [rank("officer", 2), rank("member", 3)],
      roleId: "officer",
      dateEditable: false,
    });

    expect(subject.find('[data-test="squadron-member-rank"]').exists()).toBe(
      true,
    );

    await submit(subject);

    expect(updateMember).toHaveBeenCalledWith(
      expect.objectContaining({ data: {} }),
    );
  });
});
