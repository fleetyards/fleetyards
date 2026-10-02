import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required } from "@vee-validate/rules";
import type { FleetSquadronRole } from "@/services/fyApi";
import Component from "./index.vue";

const updateRank = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useUpdateFleetSquadronRole: () => ({ mutateAsync: updateRank }),
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
  updateRank.mockReset();
});

describe("SquadronRankModal", () => {
  it("saves the new name for that rank", async () => {
    updateRank.mockResolvedValue({});
    wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: {
        fleetSlug: "maru",
        rank: {
          id: "leader-id",
          key: "leader",
          name: "Squadron Leader",
        } as FleetSquadronRole,
      },
    });

    await wrapper
      .find('[data-test="squadron-rank-name"] input')
      .setValue("Wing Commander");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(updateRank).toHaveBeenCalledWith({
      fleetSlug: "maru",
      id: "leader-id",
      data: { name: "Wing Commander" },
    });
  });
});
