import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetMember, FleetSquadron } from "@/services/fyApi";
import Component from "./index.vue";

const Stub = defineComponent({ name: "PageStub", render: () => h("div") });

// The page links to three routes and teleports its create button out of its
// own tree, so both have to exist before it mounts.
const routerWithRoutes = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      // BreadCrumbs starts at home, and every app defines that route.
      { path: "/", name: "home", component: Stub },
      { path: "/fleet", name: "fleet", component: Stub },
      { path: "/squadrons", name: "fleet-squadrons", component: Stub },
      { path: "/squadrons/new", name: "fleet-squadron-new", component: Stub },
      { path: "/squadrons/:squadron", name: "fleet-squadron", component: Stub },
    ],
  });

  await router.push("/squadrons");
  await router.isReady();

  return router;
};

const squadron = (id: string, team = false): FleetSquadron =>
  ({ id, name: id, slug: id, team, memberCount: 0 }) as FleetSquadron;

// Two of each, interleaved in the stored order, so a test cannot pass by
// accident on a list that is already grouped.
const records = [
  squadron("alpha"),
  squadron("rota", true),
  squadron("bravo"),
  squadron("watch", true),
];

type SortCall = { fleetSlug: string; data: { sorting: string[] } };

const sort = vi.fn((_variables: SortCall) => Promise.resolve());

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetSquadrons: () => ({
      data: ref({ items: records }),
      isLoading: ref(false),
      refetch: vi.fn(),
    }),
    useSortFleetSquadrons: () => ({ mutateAsync: sort }),
  };
});

let wrapper: VueWrapper | undefined;
let teleportTarget: HTMLElement | undefined;

beforeEach(() => {
  sort.mockClear();
  teleportTarget = document.createElement("div");
  teleportTarget.id = "header-right";
  document.body.appendChild(teleportTarget);
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  teleportTarget?.remove();
  teleportTarget = undefined;
});

const mount = async () => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", name: "Maru" } as Fleet,
      membership: {
        capabilities: { updateSquadrons: true, createSquadrons: true },
      } as FleetMember,
    },
    plugins: [await routerWithRoutes()],
  });

  return wrapper;
};

const grids = (subject: VueWrapper) =>
  subject.findAllComponents({ name: "BaseGrid" });

const sorting = () => sort.mock.calls[0]?.[0]?.data?.sorting;

/*
 * The page draws two rows but the position is one sequence across the fleet.
 * What goes to the server therefore has to be both rows: sending only the one
 * that was dragged would renumber it from the front and interleave it with the
 * other.
 */
describe("FleetSquadronsPage", () => {
  it("splits the stored order into squadrons and teams", async () => {
    const subject = await mount();

    expect(grids(subject)).toHaveLength(2);
    expect(grids(subject)[0].props("records")).toMatchObject([
      { id: "alpha" },
      { id: "bravo" },
    ]);
    expect(grids(subject)[1].props("records")).toMatchObject([
      { id: "rota" },
      { id: "watch" },
    ]);
  });

  it("sends both rows when the squadrons are dragged", async () => {
    const subject = await mount();

    grids(subject)[0].vm.$emit("sort", ["bravo", "alpha"]);

    expect(sorting()).toEqual(["bravo", "alpha", "rota", "watch"]);
  });

  // The half that is easy to get wrong: a dragged team row must not renumber
  // the squadrons behind it.
  it("keeps the squadrons in front when the teams are dragged", async () => {
    const subject = await mount();

    grids(subject)[1].vm.$emit("sort", ["watch", "rota"]);

    expect(sorting()).toEqual(["alpha", "bravo", "watch", "rota"]);
  });

  it("redraws the dragged row without waiting for the server", async () => {
    const subject = await mount();

    grids(subject)[1].vm.$emit("sort", ["watch", "rota"]);
    await nextTick();

    expect(grids(subject)[1].props("records")).toMatchObject([
      { id: "watch" },
      { id: "rota" },
    ]);
  });
});
