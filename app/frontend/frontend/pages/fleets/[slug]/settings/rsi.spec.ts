import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import {
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";
import { defineComponent, h } from "vue";
import { RouterView, createRouter, createWebHashHistory } from "vue-router";
import type { Fleet, FleetMember } from "@/services/fyApi";
import { defineRule } from "vee-validate";
import { alpha_dash, min, required } from "@vee-validate/rules";
import Component from "./rsi.vue";

const mutateAsync = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return { ...actual, useUpdateFleet: () => ({ mutateAsync }) };
});

const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: vi.fn(() => vi.fn()) }),
}));

let wrapper: VueWrapper | undefined;

let fleet: Fleet;

const mount = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      {
        path: "/fleets/:slug/settings/rsi/",
        name: "fleet-settings-rsi",
        component: Component,
        props: { fleet, membership: {} as FleetMember },
      },
    ],
  });

  await router.push("/fleets/test/settings/rsi/");

  wrapper = await mountWithDefaults(
    defineComponent({ render: () => h(RouterView) }),
    { plugins: [router] },
  );
  await flushPromises();

  return { wrapper, router };
};

beforeAll(() => {
  defineRule("required", required);
  defineRule("min", min);
  defineRule("alpha_dash", alpha_dash);
});

beforeEach(() => {
  fleet = { slug: "test", fid: "TEST", rsiSid: "TEST" } as Fleet;
  mutateAsync.mockReset();
  emit.mockReset();
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

describe("FleetRsiSettingsPage", () => {
  it("saves the fleet ID and the SID", async () => {
    mutateAsync.mockResolvedValue({ ...fleet, rsiSid: "OTHER" });
    const { wrapper: subject } = await mount();

    await subject.find('input[name="rsiSid"]').setValue("other");
    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync.mock.calls.at(-1)?.[0]).toMatchObject({
      slug: "test",
      data: { fid: "TEST", rsiSid: "other" },
    });
  });

  it("follows the fleet to its new address when the fleet ID changes", async () => {
    mutateAsync.mockResolvedValue({ ...fleet, fid: "NEWID", slug: "newid" });
    const { wrapper: subject, router } = await mount();

    await subject.find('input[name="fid"]').setValue("NEWID");
    await subject.find("form").trigger("submit");
    await flushPromises();

    expect(router.currentRoute.value.params.slug).toBe("newid");
  });

  it("warns when the fleet ID is not protected by a verification", async () => {
    const { wrapper: subject } = await mount();

    expect(subject.find('[data-test="fleet-fid-at-risk"]').exists()).toBe(true);
  });

  it("drops the warning once the fleet is verified for its fleet ID", async () => {
    fleet = { ...fleet, rsiVerified: true };
    const { wrapper: subject } = await mount();

    expect(subject.find('[data-test="fleet-fid-at-risk"]').exists()).toBe(
      false,
    );
  });

  it("opens the verification from the button next to the SID", async () => {
    const { wrapper: subject } = await mount();

    await subject
      .find('[data-test="fleet-rsi-verification-open"]')
      .trigger("click");

    expect(emit).toHaveBeenCalledWith(
      "open-modal",
      expect.objectContaining({ props: { fleet } }),
    );
  });

  it("asks for a typed SID to be saved before it can be verified", async () => {
    const { wrapper: subject } = await mount();

    await subject.find('input[name="rsiSid"]').setValue("OTHER");

    expect(
      subject
        .find('[data-test="fleet-rsi-verification-open"]')
        .attributes("disabled"),
    ).toBeDefined();
  });

  it("marks a verified SID and offers no second verification", async () => {
    fleet = { ...fleet, rsiVerified: true };
    const { wrapper: subject } = await mount();

    expect(subject.find('[data-test="fleet-rsi-sid-verified"]').exists()).toBe(
      true,
    );
    expect(
      subject.find('[data-test="fleet-rsi-verification-open"]').exists(),
    ).toBe(false);
  });

  it("marks an unverified SID as unverified", async () => {
    const { wrapper: subject } = await mount();

    expect(
      subject.find('[data-test="fleet-rsi-sid-unverified"]').exists(),
    ).toBe(true);
  });
});
