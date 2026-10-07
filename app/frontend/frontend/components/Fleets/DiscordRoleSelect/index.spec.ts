import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import {
  FleetDiscordConnectionCodeEnum,
  type FleetDiscordRoles,
} from "@/services/fyApi";
import Component from "./index.vue";

let response: FleetDiscordRoles;

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetDiscordRoles: () => ({
      data: ref(response),
      isLoading: ref(false),
    }),
  };
});

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  response = {
    code: FleetDiscordConnectionCodeEnum.OK,
    items: [{ id: "1", name: "Member" }],
  };
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (modelValue: string | null) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleetSlug: "maru",
      modelValue,
      name: "discordJoinRoleId",
      label: "Role",
    },
  });

  return wrapper;
};

const find = (subject: VueWrapper, name: string) =>
  subject.find(`[data-test="${name}"]`);

describe("FleetDiscordRoleSelect", () => {
  it("says nothing for a role the guild still has", async () => {
    const subject = await mount("1");

    expect(find(subject, "role-missing").exists()).toBe(false);
  });

  it("says a saved role is gone when the guild no longer lists it", async () => {
    const subject = await mount("2");

    expect(find(subject, "role-missing").exists()).toBe(true);
  });

  // An unreachable guild cannot say a role is gone.
  it("does not call a role gone while Discord is unreachable", async () => {
    response = {
      code: FleetDiscordConnectionCodeEnum.BOT_NOT_IN_GUILD,
      items: [],
    };

    const subject = await mount("2");

    expect(find(subject, "role-missing").exists()).toBe(false);
    expect(find(subject, "role-unavailable").exists()).toBe(true);
  });

  it("keeps a saved role clearable while Discord is unreachable", async () => {
    response = {
      code: FleetDiscordConnectionCodeEnum.BOT_NOT_IN_GUILD,
      items: [],
    };

    const subject = await mount("2");

    expect(subject.find("[disabled]").exists()).toBe(false);
  });

  it("is disabled with nothing saved and nothing to pick from", async () => {
    response = {
      code: FleetDiscordConnectionCodeEnum.MISSING_GUILD,
      items: [],
    };

    const subject = await mount(null);

    expect(subject.find("[disabled]").exists()).toBe(true);
  });
});
