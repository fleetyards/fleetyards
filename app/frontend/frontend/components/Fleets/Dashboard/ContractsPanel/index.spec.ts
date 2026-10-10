import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetContract } from "@/services/fyApi";
import Component from "./index.vue";

let mine: Partial<FleetContract>[] = [];
let open: Partial<FleetContract>[] = [];
let mineFails = false;
let openFails = false;
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
        data: computed(() =>
          (params.mine ? mineFails : openFails)
            ? undefined
            : { items: params.mine ? mine : open },
        ),
        isLoading: ref(false),
        isFetching: ref(false),
        isLoadingError: computed(() => (params.mine ? mineFails : openFails)),
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

const mount = async (props: { canCreate?: boolean } = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: Stub },
      { path: "/c/:slug", name: "fleet-contracts", component: Stub },
      { path: "/c/:slug/new", name: "fleet-contract-new", component: Stub },
      { path: "/c/:slug/:contract", name: "fleet-contract", component: Stub },
    ],
  });
  await router.push("/");
  await router.isReady();

  return mountWithDefaults<typeof Component>(Component, {
    props: { fleet: { slug: "maru" } as Fleet, ...props },
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
    mineFails = false;
    openFails = false;
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

  // An empty board is offered as something to start.
  it("offers somebody who may post one a new contract", async () => {
    const subject = await mount({ canCreate: true });

    expect(
      subject
        .find("[data-test='fleet-dashboard-post-contract']")
        .attributes("href"),
    ).toBe("#/c/maru/new");
  });

  it("points everybody else at the board", async () => {
    const subject = await mount();

    expect(subject.find("[data-test='fleet-dashboard-empty']").exists()).toBe(
      true,
    );
    expect(
      subject.find("[data-test='fleet-dashboard-post-contract']").exists(),
    ).toBe(false);
    expect(subject.find("a.dashboard-panel__more").attributes("href")).toBe(
      "#/c/maru",
    );
  });

  // The reader's work alone would read as nothing being open for pickup.
  it("says a group failed rather than leave it out", async () => {
    openFails = true;
    mine = [contract("a")];

    const subject = await mount();

    expect(titles(subject, "mine")).toEqual(["Job a"]);
    expect(
      subject.find("[data-test='fleet-dashboard-contracts-failed']").exists(),
    ).toBe(true);
  });

  // Without the reader's own work, their jobs would be offered back to them.
  it("offers nothing for pickup when the reader's own work failed", async () => {
    mineFails = true;
    open = [contract("a")];

    const subject = await mount();

    expect(titles(subject, "open")).toEqual([]);
    expect(subject.find("[data-test='fleet-dashboard-failed']").exists()).toBe(
      true,
    );
  });
});
