import { describe, expect, it, vi, beforeEach } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

type User = {
  tracking: boolean;
  showOnlineStatus: boolean;
  supporter: boolean;
  supporterListed: boolean | null;
};

const currentUser = ref<User>({
  tracking: true,
  showOnlineStatus: true,
  supporter: true,
  supporterListed: null,
});

const mutateAsync = vi.fn((_: unknown) => Promise.resolve());

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useUpdateProfile: () => ({ mutateAsync }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get currentUser() {
      return currentUser.value;
    },
  }),
}));

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    { path: "/settings", name: "settings", component: { template: "<div />" } },
  ],
});

import SettingsPrivacy from "./privacy.vue";

const mount = () => mountWithDefaults(SettingsPrivacy, { plugins: [router] });

const submit = async (wrapper: Awaited<ReturnType<typeof mount>>) => {
  await wrapper.find("form").trigger("submit");
  await flushPromises();
};

const sent = () =>
  (mutateAsync.mock.calls.at(-1)?.[0] as { data: Record<string, unknown> })
    .data;

describe("SettingsPrivacy", () => {
  beforeEach(() => {
    mutateAsync.mockClear();
    currentUser.value = {
      tracking: true,
      showOnlineStatus: true,
      supporter: true,
      supporterListed: null,
    };
  });

  it("offers the supporters page choice only to a supporter", async () => {
    expect(
      (await mount()).find("[data-test='supporter-listed']").exists(),
    ).toBe(true);

    currentUser.value = { ...currentUser.value, supporter: false };

    expect(
      (await mount()).find("[data-test='supporter-listed']").exists(),
    ).toBe(false);
  });

  it("does not send the choice for somebody who is not a supporter", async () => {
    currentUser.value = { ...currentUser.value, supporter: false };

    const wrapper = await mount();
    await submit(wrapper);

    expect(sent()).not.toHaveProperty("supporterListed");
  });

  // Unanswered has to stay unanswered: sending false would hide every Ko-fi
  // donation its donor marked public.
  it("keeps an unanswered choice unanswered", async () => {
    const wrapper = await mount();
    await submit(wrapper);

    expect(sent().supporterListed).toBeNull();
  });

  it("sends the choice as a boolean", async () => {
    const wrapper = await mount();

    await wrapper
      .findComponent({ name: "FormRadioList" })
      .vm.$emit("update:modelValue", "false");
    await submit(wrapper);

    expect(sent().supporterListed).toBe(false);
  });

  it("starts from a stored answer", async () => {
    currentUser.value = { ...currentUser.value, supporterListed: true };

    const wrapper = await mount();
    await submit(wrapper);

    expect(sent().supporterListed).toBe(true);
  });
});
