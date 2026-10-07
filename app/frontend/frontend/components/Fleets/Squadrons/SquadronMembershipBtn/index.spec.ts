import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import type { Fleet, FleetSquadron } from "@/services/fyApi";
import Component from "./index.vue";

const join = vi.hoisted(() => vi.fn());
const leave = vi.hoisted(() => vi.fn());
const request = vi.hoisted(() => vi.fn());
const withdraw = vi.hoisted(() => vi.fn());

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useJoinFleetSquadron: () => ({ mutateAsync: join }),
    useLeaveFleetSquadron: () => ({ mutateAsync: leave }),
    useCreateFleetSquadronRequest: () => ({ mutateAsync: request }),
    useDestroyFleetSquadronRequest: () => ({ mutateAsync: withdraw }),
  };
});

const fleet = { slug: "maru" } as Fleet;

const squadron = (overrides: Partial<FleetSquadron>) =>
  ({
    id: "1",
    name: "Mining",
    slug: "mining",
    team: false,
    memberCount: 3,
    viewerIsMember: false,
    viewerRequestedAt: null,
    ...overrides,
  }) as FleetSquadron;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  [join, leave, request, withdraw].forEach((mock) => mock.mockReset());
});

const mount = async (overrides: Partial<FleetSquadron>) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleet, squadron: squadron(overrides) },
  });

  return wrapper;
};

const click = async (subject: VueWrapper, action: string) => {
  await subject.find(`[data-test="squadron-${action}"]`).trigger("click");
  await flushPromises();
};

describe("SquadronMembershipBtn", () => {
  it("joins a team outright", async () => {
    const subject = await mount({ team: true });

    await click(subject, "join");

    expect(join).toHaveBeenCalledWith({ fleetSlug: "maru", slug: "mining" });
    expect(request).not.toHaveBeenCalled();
  });

  it("asks to join an ordinary squadron", async () => {
    const subject = await mount({});

    await click(subject, "requestJoin");

    expect(request).toHaveBeenCalledWith({
      fleetSlug: "maru",
      fleetSquadronSlug: "mining",
    });
    expect(join).not.toHaveBeenCalled();
  });

  it("offers to withdraw a request that is waiting", async () => {
    const subject = await mount({ viewerRequestedAt: "2026-10-06T10:00:00Z" });

    expect(
      subject.find('[data-test="squadron-withdrawRequest"]').exists(),
    ).toBe(true);
  });

  it("cannot ask while another request is waiting", async () => {
    const subject = await mount({
      viewerRequestedSquadron: {
        id: "2",
        name: "Bravo",
        slug: "bravo",
        team: false,
      },
    });

    const btn = subject.find('[data-test="squadron-requestJoin"]');
    expect(btn.attributes("disabled")).toBeDefined();

    await click(subject, "requestJoin");
    expect(request).not.toHaveBeenCalled();
  });

  it("cannot ask while already in another squadron", async () => {
    const subject = await mount({
      viewerExclusiveSquadron: {
        id: "2",
        name: "Bravo",
        slug: "bravo",
        team: false,
      },
    });

    expect(
      subject.find('[data-test="squadron-requestJoin"]').attributes("disabled"),
    ).toBeDefined();
  });

  it("still joins a team while committed elsewhere", async () => {
    const subject = await mount({
      team: true,
      viewerRequestedSquadron: {
        id: "2",
        name: "Bravo",
        slug: "bravo",
        team: false,
      },
    });

    await click(subject, "join");

    expect(join).toHaveBeenCalled();
  });

  it("offers a member to leave, team or not", async () => {
    const subject = await mount({ team: true, viewerIsMember: true });

    expect(subject.find('[data-test="squadron-leave"]').exists()).toBe(true);
    expect(subject.find('[data-test="squadron-join"]').exists()).toBe(false);
  });
});
