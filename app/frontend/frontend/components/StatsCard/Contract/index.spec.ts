import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { FleetContractDetail } from "@/services/fyApi";
import ContractStatsCard from "./index.vue";

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/", name: "home", component: { template: "<div />" } }],
  });

const contract = (overrides: Partial<FleetContractDetail> = {}) =>
  ({
    id: "1",
    title: "Salvage Run",
    slug: "salvage-run",
    kind: "transport",
    state: "open",
    reward: "5000.0",
    rewardType: "fixed",
    progress: { lines: [] },
    deadline: null,
    ...overrides,
  }) as unknown as FleetContractDetail;

const mountCard = (record: FleetContractDetail) =>
  mountWithDefaults(ContractStatsCard, {
    props: { contract: record },
    plugins: [router()],
  });

const reward = async (record: FleetContractDetail) =>
  (await mountCard(record)).find("[title]").attributes("title");

describe("ContractStatsCard", () => {
  it("shows a contract's reward", async () => {
    expect(await reward(contract())).toMatch(/5.?000/);
  });

  it("says a contract pays nothing rather than showing it as missing", async () => {
    expect(
      await reward(contract({ reward: "0.0", rewardType: "none" as never })),
    ).toBe("No reward");
  });

  it("quotes a per-unit reward in the unit its lines are measured in", async () => {
    const wrapper = await mountCard(
      contract({
        reward: "12.5",
        rewardType: "per_unit" as never,
        progress: { lines: [{ unit: "scu" }] } as never,
      }),
    );

    expect(wrapper.find("[title]").attributes("title")).toBe("12.5");
    expect(wrapper.text()).toContain("/ SCU");
  });
});
