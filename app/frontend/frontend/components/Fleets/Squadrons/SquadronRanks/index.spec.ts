import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import type { FleetSquadronRole } from "@/services/fyApi";
import Component from "./index.vue";

const ranks = [
  {
    id: "1",
    key: "leader",
    name: "Wing Commander",
    position: 0,
    singleHolder: true,
    managesMembers: true,
    managesRanks: true,
  },
  {
    id: "4",
    key: "member",
    name: "Member",
    position: 3,
    singleHolder: false,
    managesMembers: false,
    managesRanks: false,
  },
] as FleetSquadronRole[];

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (editable: boolean) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleetSlug: "maru", ranks, editable },
  });

  return wrapper;
};

describe("SquadronRanks", () => {
  it("shows what each rank may do, as the server reports it", async () => {
    const subject = await mount(false);

    const leader = subject.find('[data-test="squadron-rank-leader"]');
    const member = subject.find('[data-test="squadron-rank-member"]');

    expect(leader.text()).toContain("Wing Commander");
    expect(leader.findAll(".squadron-rank-right.active")).toHaveLength(3);
    expect(member.findAll(".squadron-rank-right.active")).toHaveLength(0);
  });

  it("offers the rename only to a reader who may rename", async () => {
    const readOnly = await mount(false);
    expect(
      readOnly.find('[data-test="squadron-rank-edit-leader"]').exists(),
    ).toBe(false);
    readOnly.unmount();

    const editable = await mount(true);
    expect(
      editable.find('[data-test="squadron-rank-edit-leader"]').exists(),
    ).toBe(true);
  });
});
