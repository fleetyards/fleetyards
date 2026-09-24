import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import {
  FleetDiscordConnectionCodeEnum,
  type FleetDiscordChannels,
} from "@/services/fyApi";
import Component from "./index.vue";

let response: FleetDiscordChannels;

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetDiscordChannels: () => ({
      data: ref(response),
      isLoading: ref(false),
    }),
  };
});

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  response = {
    code: FleetDiscordConnectionCodeEnum.OK,
    items: [{ id: "1", name: "ops", parentName: "General" }],
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
      name: "discordChannelId",
      label: "Channel",
    },
  });

  return wrapper;
};

const find = (subject: VueWrapper, name: string) =>
  subject.find(`[data-test="${name}"]`);

describe("FleetDiscordChannelSelect", () => {
  it("says nothing for a channel the guild still has", async () => {
    const subject = await mount("1");

    expect(find(subject, "channel-missing").exists()).toBe(false);
  });

  it("says a saved channel is gone when the guild no longer lists it", async () => {
    const subject = await mount("2");

    expect(find(subject, "channel-missing").exists()).toBe(true);
  });

  // An unreachable guild cannot say a channel is gone.
  it("does not call a channel gone while Discord is unreachable", async () => {
    response = {
      code: FleetDiscordConnectionCodeEnum.BOT_NOT_IN_GUILD,
      items: [],
    };

    const subject = await mount("2");

    expect(find(subject, "channel-missing").exists()).toBe(false);
    expect(find(subject, "channel-unavailable").exists()).toBe(true);
  });
});
