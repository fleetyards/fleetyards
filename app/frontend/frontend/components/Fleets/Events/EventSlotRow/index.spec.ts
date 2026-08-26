import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import {
  type FleetEventSignup,
  type FleetEventSlot,
  FleetEventSignupStatusEnum,
  FleetEventSignupApprovalEnum,
  FleetEventSlottableTypeEnum,
} from "@/services/fyApi";

const CURRENT_USER = "user-me";

const signup = (
  userId: string,
  status = FleetEventSignupStatusEnum.CONFIRMED,
): FleetEventSignup => ({
  id: `signup-${userId}`,
  fleetEventId: "event-1",
  status,
  user: { id: userId, username: userId },
});

const slot = (overrides: Partial<FleetEventSlot> = {}): FleetEventSlot => ({
  id: "slot-1",
  slottableType: FleetEventSlottableTypeEnum.FLEET_EVENT_SHIP,
  slottableId: "ship-1",
  title: "Pilot",
  position: 0,
  derived: false,
  effectiveSignupApproval: FleetEventSignupApprovalEnum.DIRECT,
  signups: [],
  ...overrides,
});

const mount = (record: FleetEventSlot, props: Record<string, unknown> = {}) =>
  mountWithDefaults<typeof Component>(Component, {
    props: {
      slotData: record,
      currentUserId: CURRENT_USER,
      signupsLocked: false,
      signupsOpen: true,
      ...props,
    },
  });

describe("FleetEventsSlotRow", () => {
  it("is a list row, not a nested card", async () => {
    // D4: six slots on a ship used to stack six bordered boxes inside a card
    // inside a panel. One hairline per row is the app's repeated-record idiom.
    const wrapper = await mount(slot());

    expect(wrapper.find(".event-slot-row").exists()).toBe(true);
    expect(wrapper.find(".event-slot-row--mine").exists()).toBe(false);
  });

  it("marks your own slot with the rail rather than a recoloured border", async () => {
    const wrapper = await mount(slot({ signups: [signup(CURRENT_USER)] }));

    expect(wrapper.find(".event-slot-row--mine").exists()).toBe(true);
  });

  it("names your own slot with a chip rather than a bare tinted pill", async () => {
    // The pill it replaces was 999px, teal, and signalled by colour alone.
    const wrapper = await mount(slot({ signups: [signup(CURRENT_USER)] }));

    expect(wrapper.find(".chip").exists()).toBe(true);
  });

  it("offers signup on a free slot and withholds it on a taken one", async () => {
    const free = await mount(slot());
    expect(free.find("button.btn").attributes("disabled")).toBeUndefined();

    const taken = await mount(slot({ signups: [signup("someone-else")] }));
    expect(taken.find("button.btn").attributes("disabled")).toBeDefined();
  });

  it("withholds signup while the event is locked", async () => {
    const wrapper = await mount(slot(), {
      signupsLocked: true,
      signupsOpen: false,
    });

    expect(wrapper.find("button.btn").attributes("disabled")).toBeDefined();
  });

  it("uses chip-scale controls, not the toolbar scale", async () => {
    // D4: at row density the answer is xs (29px), not the new sm default -
    // which is the one place F1's mechanical size mapping is deliberately not
    // mechanical.
    const wrapper = await mount(slot());

    expect(wrapper.find("button.btn--xs").exists()).toBe(true);
  });
});
