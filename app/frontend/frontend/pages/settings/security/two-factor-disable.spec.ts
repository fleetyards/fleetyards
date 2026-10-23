import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { createRouter, createMemoryHistory } from "vue-router";
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

beforeAll(() => {
  defineRule("required", required);
});

describe("TwoFactorDisable", () => {
  beforeEach(() => {
    mutateAsync.mockReset();
    mutateAsync.mockResolvedValue(undefined);
  });

  it("sends a code pasted with spaces without them", async () => {
    await submitCode(await mount(), " 123 456 ");

    expect(mutateAsync).toHaveBeenCalledWith({ data: { otpCode: "123456" } });
  });
});
