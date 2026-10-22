import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { ref } from "vue";
import { AxiosError, type AxiosResponse } from "axios";

const syncToDiscord = vi.fn();
const displayAlert = vi.fn();

const KNOWN_KEYS = new Set([
  "messages.fleets.event.syncToDiscord.discord_missing_permissions",
]);

vi.mock("@/services/fyApi", () => {
  const idle = () => ({ mutateAsync: vi.fn(), isPending: ref(false) });

  return {
    usePublishFleetEvent: idle,
    useLockFleetEventSignups: idle,
    useUnlockFleetEventSignups: idle,
    useStartFleetEvent: idle,
    useCompleteFleetEvent: idle,
    useCancelFleetEvent: idle,
    useUnarchiveFleetEvent: idle,
    useSyncFleetEventToDiscord: () => ({
      mutateAsync: syncToDiscord,
      isPending: ref(false),
    }),
    useDestroyFleetEvent: idle,
  };
});

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    tExists: (key: string) => KNOWN_KEYS.has(key),
  }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert,
    displayConfirm: vi.fn(),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn() }),
}));

vi.mock("vue-router", () => ({
  useRouter: () => ({ push: vi.fn() }),
}));

import EventAdminActions from "./index.vue";

const refusal = (code: string) =>
  new AxiosError("Bad Gateway", "ERR_BAD_RESPONSE", undefined, undefined, {
    status: 502,
    data: { code, message: "Discord API error" },
  } as AxiosResponse);

const clickSync = async () => {
  const wrapper = mount(EventAdminActions, {
    props: {
      fleet: { slug: "maru" } as never,
      event: {
        slug: "op-night",
        status: "open",
        archived: false,
        discordConfigured: true,
      } as never,
      resourceAccess: ["fleet:manage"],
    },
    global: {
      stubs: {
        teleport: true,
        // The menu only renders its items once opened.
        BtnDropdown: { template: "<div><slot /></div>" },
      },
    },
  });
  const button = wrapper
    .findAll("button")
    .find((candidate) =>
      candidate.text().includes("actions.fleets.events.syncToDiscord"),
    )!;

  await button.trigger("click");
  await flushPromises();
};

describe("FleetEventAdminActions sync to Discord", () => {
  beforeEach(() => {
    syncToDiscord.mockReset();
    displayAlert.mockReset();
  });

  it("points at the missing permission when Discord refuses the bot", async () => {
    syncToDiscord.mockRejectedValue(refusal("discord_missing_permissions"));

    await clickSync();

    expect(displayAlert).toHaveBeenCalledWith({
      text: "messages.fleets.event.syncToDiscord.discord_missing_permissions",
    });
  });

  it("falls back to the generic failure for anything else", async () => {
    syncToDiscord.mockRejectedValue(refusal("discord_error"));

    await clickSync();

    expect(displayAlert).toHaveBeenCalledWith({
      text: "messages.fleets.event.syncToDiscord.failure",
    });
  });
});
