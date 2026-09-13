import { mount, flushPromises } from "@vue/test-utils";
import { createTestingPinia } from "@pinia/testing";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { Friendship } from "@/services/fyApi";

const friendship = ref<Partial<Friendship> | undefined>(undefined);
const isLoading = ref(false);
const refetch = vi.fn(() => Promise.resolve());
const createFriendship = vi.fn(() => Promise.resolve());
const acceptFriendship = vi.fn(() => Promise.resolve());

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useFriendship: () => ({ data: friendship, isLoading, refetch }),
  useCreateFriendship: () => ({ mutateAsync: createFriendship }),
  useAcceptFriendship: () => ({ mutateAsync: acceptFriendship }),
}));

const features = ref<string[]>(["friends"]);

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
    displayInfo: vi.fn(),
    displaySuccess: vi.fn(),
    displayWarning: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

import Component from "./index.vue";

const mountButton = async (reader?: string) => {
  const wrapper = mount(Component, {
    props: { username: "gustav" },
    global: {
      plugins: [
        createTestingPinia({
          initialState: {
            session: {
              authenticated: !!reader,
              currentUser: reader ? { username: reader } : undefined,
            },
          },
        }),
      ],
    },
  });

  await flushPromises();

  return wrapper;
};

describe("RelationshipsFriendButton", () => {
  beforeEach(() => {
    friendship.value = undefined;
    isLoading.value = false;
    features.value = ["friends"];
    createFriendship.mockClear();
    acceptFriendship.mockClear();
  });

  // The 404 the friendship endpoint answers with is the common case here: no
  // row between these two, which is exactly when the button has something to do.
  it("asks when there is no relationship", async () => {
    const wrapper = await mountButton("marten");

    expect(wrapper.find('[data-test="friend-add"]').exists()).toBe(true);

    await wrapper.find('[data-test="friend-add"]').trigger("click");
    await flushPromises();

    expect(createFriendship).toHaveBeenCalledWith({
      data: { username: "gustav" },
    });
  });

  // Sending a second request into a crossing one would work -- the endpoint
  // accepts it -- but the button should say what it does.
  it("answers an incoming request rather than sending another", async () => {
    friendship.value = { state: "pending", direction: "incoming" };
    const wrapper = await mountButton("marten");

    expect(wrapper.find('[data-test="friend-add"]').exists()).toBe(false);

    await wrapper.find('[data-test="friend-accept"]').trigger("click");
    await flushPromises();

    expect(acceptFriendship).toHaveBeenCalledWith({ username: "gustav" });
  });

  it("says a request is waiting and offers nothing to press", async () => {
    friendship.value = { state: "pending", direction: "outgoing" };
    const wrapper = await mountButton("marten");

    const button = wrapper.find('[data-test="friend-requested"]');

    expect(button.exists()).toBe(true);
    expect(button.attributes("disabled")).toBeDefined();
  });

  it("says so once the two are friends", async () => {
    friendship.value = { state: "accepted", direction: "outgoing" };
    const wrapper = await mountButton("marten");

    expect(wrapper.find('[data-test="friend-accepted"]').exists()).toBe(true);
  });

  // Only the party who ignored a request ever reads `ignored`, and a further
  // request from them is absorbed -- a button that goes nowhere.
  it("offers nothing on a request this reader ignored", async () => {
    friendship.value = { state: "ignored", direction: "incoming" };
    const wrapper = await mountButton("marten");

    expect(wrapper.find("button").exists()).toBe(false);
  });

  it("stays off the reader's own hangar, whatever the casing", async () => {
    const wrapper = await mountButton("Gustav");

    expect(wrapper.find("button").exists()).toBe(false);
  });

  it("stays away from a reader who is not signed in", async () => {
    const wrapper = await mountButton();

    expect(wrapper.find("button").exists()).toBe(false);
  });

  it("stays away while the flag is off", async () => {
    features.value = [];
    const wrapper = await mountButton("marten");

    expect(wrapper.find("button").exists()).toBe(false);
  });

  it("waits for the answer before offering anything", async () => {
    isLoading.value = true;
    const wrapper = await mountButton("marten");

    expect(wrapper.find("button").exists()).toBe(false);
  });
});
