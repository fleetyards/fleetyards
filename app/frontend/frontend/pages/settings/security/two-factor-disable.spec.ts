import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
import { AxiosError, type AxiosResponse } from "axios";
import { defineRule } from "vee-validate";
import { required } from "@vee-validate/rules";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const mutateAsync = vi.fn((_: unknown): Promise<unknown> => Promise.resolve());

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useDisableOtpSetup: () => ({ mutateAsync }),
}));

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({ currentUser: ref({ twoFactorRequired: true }) }),
}));

const displayAlert = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess: vi.fn(), displayAlert }),
}));

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    {
      path: "/settings/security",
      name: "settings-security",
      component: { template: "<div />" },
    },
  ],
});

import TwoFactorDisable from "./two-factor-disable.vue";

const mount = () => mountWithDefaults(TwoFactorDisable, { plugins: [router] });

const submitCode = async (
  wrapper: Awaited<ReturnType<typeof mount>>,
  code: string,
) => {
  await wrapper.find("input").setValue(code);
  await wrapper.find("form").trigger("submit");
  await flushPromises();
};

const rejection = (code: string) =>
  new AxiosError("Request failed", "ERR_BAD_REQUEST", undefined, undefined, {
    status: 400,
    data: { code, message: "Could not deactivate Two-factor Authentication" },
  } as AxiosResponse);

beforeAll(() => {
  defineRule("required", required);
});

describe("TwoFactorDisable", () => {
  beforeEach(() => {
    mutateAsync.mockReset();
    mutateAsync.mockResolvedValue(undefined);
    displayAlert.mockClear();
  });

  it("marks a rejected code on the field instead of raising an alert", async () => {
    mutateAsync.mockRejectedValue(rejection("otp.disable.failure"));

    const wrapper = await mount();
    await submitCode(wrapper, "123456");

    expect(displayAlert).not.toHaveBeenCalled();
    expect(wrapper.text()).toContain("This code is not valid.");
  });

  it("still raises an alert for any other failure", async () => {
    mutateAsync.mockRejectedValue(rejection("otp.inactive"));

    await submitCode(await mount(), "123456");

    expect(displayAlert).toHaveBeenCalled();
  });
});
