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
    deadline: null,
    ...overrides,
  }) as unknown as FleetContractDetail;

const reward = async (record: FleetContractDetail) => {
  const wrapper = await mountWithDefaults(ContractStatsCard, {
    props: { contract: record },
    plugins: [router()],
  });

  return wrapper.find("[title]").attributes("title");
};

describe("ContractStatsCard", () => {
  it("shows a contract's reward", async () => {
    expect(await reward(contract())).toMatch(/5.?000/);
  });

  it("shows a reward of nothing as zero rather than as missing", async () => {
    expect(await reward(contract({ reward: "0.0" }))).toBe("0");
  });
});
