import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required } from "@vee-validate/rules";
import type { FleetSquadronRole } from "@/services/fyApi";
import Component from "./index.vue";

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useUpdateFleetSquadronRole: () => ({ mutateAsync: vi.fn() }),
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

beforeAll(() => {
  defineRule("required", required);
});

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

  it("offers the names for editing only when the reader may rename", async () => {
    const readOnly = await mount(false);
    expect(
      readOnly.find('[data-test="squadron-rank-name-leader"]').exists(),
    ).toBe(false);
    readOnly.unmount();

    const editable = await mount(true);
    expect(
      editable.find('[data-test="squadron-rank-name-leader"]').exists(),
    ).toBe(true);
  });
});
