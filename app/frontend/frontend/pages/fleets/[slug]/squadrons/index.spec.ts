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

type MoveCall = { fleetSlug: string; slug: string; data: { position: number } };

const move = vi.fn((_variables: MoveCall) => Promise.resolve());

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
    useMoveFleetSquadron: () => ({ mutateAsync: move }),
  };
});

let wrapper: VueWrapper | undefined;
let teleportTarget: HTMLElement | undefined;

beforeEach(() => {
  move.mockClear();
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

const moveSent = () => {
  const call = move.mock.calls[0]?.[0];

  return call && { slug: call.slug, position: call.data.position };
};

/*
 * The page draws two rows but the order is one sequence across the fleet, with
 * the two interleaved. A move is therefore counted in that sequence: counted
 * within its row it would land among the other row.
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

  // alpha, rota, bravo, watch: alpha dropped behind bravo goes after bravo in
  // the whole sequence, past the team between them.
  it("places a dragged squadron after the one now ahead of it", async () => {
    const subject = await mount();

    grids(subject)[0].vm.$emit("sort", ["bravo", "alpha"]);

    expect(moveSent()).toEqual({ slug: "alpha", position: 2 });
  });

  // The half that is easy to get wrong: a team dragged within its row must not
  // land among the squadrons.
  it("places a dragged team after the team now ahead of it", async () => {
    const subject = await mount();

    grids(subject)[1].vm.$emit("sort", ["watch", "rota"]);

    expect(moveSent()).toEqual({ slug: "rota", position: 3 });
  });

  it("sends one move per drag", async () => {
    const subject = await mount();

    grids(subject)[0].vm.$emit("sort", ["bravo", "alpha"]);

    expect(move).toHaveBeenCalledTimes(1);
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
