import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import type {
  Fleet,
  FleetMember,
  FleetSquadron,
  FleetSquadronRef,
} from "@/services/fyApi";
import Component from "./index.vue";

const squadronRef = (
  overrides: Partial<FleetSquadronRef> = {},
): FleetSquadronRef =>
  ({
    id: "combat",
    name: "Combat Wing",
    slug: "combat-wing",
    team: false,
    ...overrides,
  }) as FleetSquadronRef;

const member = (overrides: Partial<FleetMember> = {}): FleetMember =>
  ({
    id: "1",
    username: "hauler",
    squadrons: [],
    ...overrides,
  }) as FleetMember;

const members = [
  member({ id: "1", username: "free" }),
  member({
    id: "2",
    username: "spoken-for",
    squadrons: [squadronRef()],
  }),
  member({
    id: "3",
    username: "on-the-rota",
    squadrons: [squadronRef({ id: "sar", name: "Rescue", team: true })],
  }),
  // Already in the squadron under test, so the picker opens with them ticked.
  member({
    id: "4",
    username: "settled",
    squadrons: [squadronRef({ id: "mining", name: "Mining", team: false })],
  }),
];

const addMember = vi.fn(() => Promise.resolve());
const removeMember = vi.fn(() => Promise.resolve());

// The list is the picker's own paged query; the rule under test is what it does
// with the members once it has them.
vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetMembers: () => ({
      data: ref({ items: members, meta: { pagination: { totalPages: 1 } } }),
      isLoading: ref(false),
    }),
    useCreateFleetSquadronMember: () => ({ mutateAsync: addMember }),
    useDestroyFleetSquadronMember: () => ({ mutateAsync: removeMember }),
  };
});

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  addMember.mockClear();
  removeMember.mockClear();
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (team: boolean) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", name: "Maru" } as Fleet,
      squadron: {
        id: "mining",
        name: "Mining",
        slug: "mining",
        team,
      } as FleetSquadron,
    },
  });

  return wrapper;
};

const card = (subject: VueWrapper, username: string) =>
  subject.find(`[data-test="squadron-member-option-${username}"]`);

/*
 * A member belongs to one squadron; a team takes anybody. The server refuses
 * the join either way -- the picker's job is to make the refusal visible before
 * the click rather than as a count of failures afterwards.
 */
describe("FleetSquadronMemberPicker", () => {
  it("blocks somebody who already has a squadron", async () => {
    const subject = await mount(false);

    expect(card(subject, "spoken-for").attributes("disabled")).toBeDefined();
  });

  it("leaves somebody who is only on a team alone", async () => {
    const subject = await mount(false);

    expect(card(subject, "on-the-rota").attributes("disabled")).toBeUndefined();
  });

  it("blocks nobody when this squadron is itself a team", async () => {
    const subject = await mount(true);

    expect(card(subject, "spoken-for").attributes("disabled")).toBeUndefined();
  });

  it("selects a member who is free to be picked", async () => {
    const subject = await mount(false);

    await card(subject, "free").trigger("click");

    expect(card(subject, "free").classes()).toContain(
      "member-picker__card--selected",
    );
  });

  // The attribute is the guard; this is the behaviour it buys.
  it("does not select a blocked member when their card is clicked", async () => {
    const subject = await mount(false);

    await card(subject, "spoken-for").trigger("click");

    expect(card(subject, "spoken-for").classes()).not.toContain(
      "member-picker__card--selected",
    );
  });

  /*
   * Taking somebody out of a squadron has to be possible somewhere, and this is
   * where the roster is already in front of you -- which matters more now that
   * a member holds one squadron, so moving them means taking them out of the
   * one they have.
   */
  it("opens with the members it already holds ticked", async () => {
    const subject = await mount(false);

    expect(card(subject, "settled").classes()).toContain(
      "member-picker__card--selected",
    );
    expect(card(subject, "free").classes()).not.toContain(
      "member-picker__card--selected",
    );
  });

  it("removes a member who is unticked", async () => {
    const subject = await mount(false);

    await card(subject, "settled").trigger("click");
    await subject.find('[data-test="squadron-save-members"]').trigger("click");

    expect(removeMember).toHaveBeenCalledWith(
      expect.objectContaining({ username: "settled" }),
    );
    expect(addMember).not.toHaveBeenCalled();
  });

  it("adds a member who is ticked", async () => {
    const subject = await mount(false);

    await card(subject, "free").trigger("click");
    await subject.find('[data-test="squadron-save-members"]').trigger("click");

    expect(addMember).toHaveBeenCalledWith(
      expect.objectContaining({ data: { username: "free" } }),
    );
    expect(removeMember).not.toHaveBeenCalled();
  });

  // Ticking somebody who was already in is not a request.
  it("writes nothing when the roster is left as it was", async () => {
    const subject = await mount(false);

    expect(
      subject
        .find('[data-test="squadron-save-members"]')
        .attributes("disabled"),
    ).toBeDefined();
  });
});
