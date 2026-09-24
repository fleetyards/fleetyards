import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import {
  type FleetContractProgressSummary,
  FleetContractStateEnum,
} from "@/services/fyApi";
import Component from "./index.vue";

const progress = (
  overrides: Partial<FleetContractProgressSummary> = {},
): FleetContractProgressSummary => ({
  fraction: 0.3,
  delivered: "240.0",
  requested: "800.0",
  unit: "scu",
  complete: false,
  ...overrides,
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (props: InstanceType<typeof Component>["$props"]) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, { props });

  return wrapper;
};

describe("FleetContractsDeliveredBar", () => {
  it("shows an expired contract's partial delivery", async () => {
    const subject = await mount({
      progress: progress(),
      state: FleetContractStateEnum.EXPIRED,
    });

    expect(subject.classes()).toContain("delivered-bar--underway");
  });

  it.each([FleetContractStateEnum.DRAFT, FleetContractStateEnum.CANCELLED])(
    "keeps a %s contract quiet",
    async (state) => {
      const subject = await mount({ progress: progress(), state });

      expect(subject.classes()).toContain("delivered-bar--quiet");
    },
  );
});
