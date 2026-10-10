import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetContract } from "@/services/fyApi";
import Component from "./index.vue";

let mine: Partial<FleetContract>[] = [];
let open: Partial<FleetContract>[] = [];
const asked: { mine?: boolean; perPage?: number }[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetContracts: (
      _slug: unknown,
      params: { mine?: boolean; perPage?: number },
    ) => {
      asked.push(params);

      return {
        data: computed(() => ({ items: params.mine ? mine : open })),
        isLoading: ref(false),
      };
    },
  };
});

const Stub = defineComponent({ render: () => h("div") });

const contract = (id: string): Partial<FleetContract> => ({
  id,
  slug: id,
  title: `Job ${id}`,
  kind: "transport",
  state: "open",
  reward: "0",
});

const mount = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/c/:slug", name: "fleet-contracts", component: Stub },
      { path: "/c/:slug/:contract", name: "fleet-contract", component: Stub },
    ],
  });
  await router.push("/");
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "maru" } as Fleet },
    plugins: [router],
  });
};

const titles = (subject: Awaited<ReturnType<typeof mount>>, group: string) =>
  subject
    .findAll(
      `[data-test='fleet-dashboard-contracts-${group}'] .contracts-panel__title`,
    )
    .map((title) => title.text());

describe("FleetDashboardContractsPanel", () => {
  beforeEach(() => {
    mine = [];
    open = [];
    asked.length = 0;
  });

  // The reader's own work is taken out of the open list, so it asks for more
  // than it shows, or working the newest jobs would empty the group.
  it("still fills the open group when the reader works the newest jobs", async () => {
    mine = ["a", "b", "c", "d"].map(contract);
    open = ["a", "b", "c", "d", "e", "f", "g", "h"].map(contract);

    const subject = await mount();

    expect(asked.find((params) => !params.mine)?.perPage).toBe(8);
    expect(titles(subject, "open")).toEqual([
      "Job e",
      "Job f",
      "Job g",
      "Job h",
    ]);
  });
});
