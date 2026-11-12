import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type Sortable from "sortablejs";
import Component from "./index.vue";
import {
  type Fleet,
  type FleetSquadron,
  type FleetSquadronFlight,
  type MissionShip,
} from "@/services/fyApi";

// jsdom has no pointer, so the drag is played back through the options
// Sortable was created with.
let options: Sortable.Options | undefined;
let container: HTMLElement | undefined;

vi.mock("sortablejs", () => ({
  default: {
    create: vi.fn((el: HTMLElement, opts: Sortable.Options) => {
      options = opts;
      container = el;
      return { destroy: vi.fn() };
    }),
  },
}));

const sortShips = vi.fn(() => Promise.resolve());

vi.mock(
  "@/frontend/components/Fleets/Missions/useLineupApi",
  async (importOriginal) => ({
    ...(await importOriginal<object>()),
    useLineupApi: () => ({ sortShips, isPending: ref(false) }),
  }),
);

const ship = (id: string): MissionShip =>
  ({
    id,
    missionTeamId: "team-1",
    title: id,
    position: 0,
    strict: false,
    allowedModels: [],
    slots: [],
  }) as MissionShip;

const mount = (editable: boolean) =>
  mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "fleet" } as Fleet,
      squadron: { slug: "alpha" } as FleetSquadron,
      flight: {
        id: "flight-1",
        teamId: "team-1",
        slots: [],
        ships: [ship("a"), ship("b"), ship("c")],
      } as unknown as FleetSquadronFlight,
      editable,
    },
    attachTo: document.body,
  });

const renderedOrder = () =>
  Array.from(
    container?.querySelectorAll<HTMLElement>("[data-ship-id]") ?? [],
  ).map((el) => el.dataset.shipId);

describe("FleetSquadronFlightLineup", () => {
  beforeEach(() => {
    options = undefined;
    container = undefined;
    sortShips.mockClear();
  });

  it("does not arm sorting for a reader", async () => {
    await mount(false);

    expect(options).toBeUndefined();
  });

  it("saves the new ship order and renders it", async () => {
    await mount(true);
    await nextTick();

    expect(options?.handle).toBe(".flight-ship__grip");

    // What Sortable does to the DOM before it calls onEnd: "c" to the front.
    const item = container!.children[2] as HTMLElement;
    container!.insertBefore(item, container!.children[0]);

    options!.onEnd!({
      item,
      from: container!,
      oldIndex: 2,
      newIndex: 0,
    } as unknown as Sortable.SortableEvent);
    await nextTick();

    expect(sortShips).toHaveBeenCalledWith(["c", "a", "b"]);
    expect(renderedOrder()).toEqual(["c", "a", "b"]);
  });
});
