import { flushPromises, mount } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { beforeEach, describe, expect, it, vi } from "vitest";

const features = ref<string[]>(["oauth-discord", "oauth-github"]);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: (feature: string) => features.value.includes(feature),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useDisconnectOauthProvider: () => ({ mutateAsync: vi.fn() }),
}));

import Component from "./index.vue";

const mountLogins = async (session: {
  authenticated: boolean;
  connections: string[];
}) => {
  const wrapper = mount(Component, {
    global: {
      plugins: [
        createTestingPinia({
          initialState: {
            session: {
              authenticated: session.authenticated,
              currentUser: {
                username: "marten",
                authConnections: session.connections,
              },
            },
          },
        }),
      ],
    },
  });

  await flushPromises();

  return wrapper;
};

const buttonStates = (wrapper: Awaited<ReturnType<typeof mountLogins>>) =>
  wrapper.findAll('[data-test="oauth-btn"]').map((btn) => ({
    disabled: btn.attributes("disabled") !== undefined,
    connected: btn.find(".fa-check").exists(),
  }));

describe("SocialLogins", () => {
  beforeEach(() => {
    features.value = ["oauth-discord", "oauth-github"];
  });

  it("marks the providers the signed-in user has connected", async () => {
    const wrapper = await mountLogins({
      authenticated: true,
      connections: ["discord"],
    });

    expect(buttonStates(wrapper)).toEqual([
      { disabled: true, connected: true },
      { disabled: false, connected: false },
    ]);
  });

  // A session that ended outside this store's own logout leaves `currentUser`
  // behind. Read as connections, every button on the login page renders
  // connected -- and a connected button is disabled, so the stale account takes
  // away the only control that could sign anybody back in.
  it("offers every provider to a signed-out visitor", async () => {
    const wrapper = await mountLogins({
      authenticated: false,
      connections: ["discord", "github"],
    });

    expect(buttonStates(wrapper)).toEqual([
      { disabled: false, connected: false },
      { disabled: false, connected: false },
    ]);
  });
});
