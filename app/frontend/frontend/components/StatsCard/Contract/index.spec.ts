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

  it("quotes a rate every line shares in the unit its lines are measured in", async () => {
    const wrapper = await mountCard(
      contract({
        reward: "0.0",
        rewardRate: "12.5",
        rewardType: "per_unit" as never,
        progress: { lines: [{ unit: "scu" }] } as never,
      }),
    );

    expect(wrapper.find("[title]").attributes("title")).toBe("12.5");
    expect(wrapper.text()).toContain("/ SCU");
  });

  it("reads rates that differ per line as the most they pay", async () => {
    const wrapper = await mountCard(
      contract({
        reward: "0.0",
        rewardRate: null,
        maxReward: "29000.0",
        rewardType: "per_unit" as never,
        progress: { lines: [{ unit: "scu" }] } as never,
      }),
    );

    expect(wrapper.find("[title]").attributes("title")).toMatch(/29.?000/);
    expect(wrapper.text()).toContain("Reward, up to");
  });

  it("says how a per-unit contract pays before any line has a rate", async () => {
    expect(
      await reward(
        contract({
          reward: "0.0",
          rewardRate: null,
          maxReward: "0.0",
          rewardType: "per_unit" as never,
        }),
      ),
    ).toBe("Per SCU or unit delivered");
  });
});
