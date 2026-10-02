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
import { defineRule } from "vee-validate";
import {
  FeatureFlagName,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Component from "./fleet.vue";

const mutateAsync = vi.fn();

// It previews 3D models through the holo viewer, a graph the test environment
// cannot load and nothing this spec is about.
vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: { name: "FormFileInput", render: () => null },
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
    displayConfirm: vi.fn(),
  }),
}));

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useUpdateFleet: () => ({ mutateAsync }),
    useDestroyFleet: () => ({ mutateAsync: vi.fn() }),
  };
});

let wrapper: VueWrapper | undefined;

beforeAll(() => {
  ["required", "min", "max", "fleetName"].forEach((rule) =>
    defineRule(rule, () => true),
  );
});

beforeEach(() => {
  mutateAsync.mockReset().mockResolvedValue({});
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const verifiedFleet = (overrides: Partial<Fleet> = {}) =>
  ({
    slug: "maru",
    name: "Maru Fleet",
    publicFleet: true,
    rsiVerified: true,
    listed: null,
    alignment: null,
    primaryActivity: "piracy",
    secondaryActivity: null,
    language: "de",
    commitment: "casual",
    recruiting: true,
    roleplay: false,
    features: [FeatureFlagName.FLEET_DIRECTORY],
    ...overrides,
  }) as Fleet;

const manager = { capabilities: { manageFleet: true } } as FleetMember;

const mount = async (fleet: Fleet, membership: FleetMember = manager) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleet, membership },
  });
  await flushPromises();

  return wrapper;
};

const listedToggle = (subject: VueWrapper) =>
  subject
    .findAllComponents(FormToggle)
    .find((toggle) => toggle.props("name") === "listed");

const save = async (subject: VueWrapper) => {
  await subject.find("form").trigger("submit");
  await flushPromises();
};

describe("fleet settings: directory", () => {
  it("is hidden until the fleet is verified", async () => {
    const subject = await mount(verifiedFleet({ rsiVerified: false }));

    expect(
      subject.find('[data-test="fleet-directory-settings"]').exists(),
    ).toBe(false);
  });

  it("is hidden while the directory is not rolled out to the fleet", async () => {
    const subject = await mount(verifiedFleet({ features: [] }));

    expect(
      subject.find('[data-test="fleet-directory-settings"]').exists(),
    ).toBe(false);
  });

  it("shows a fleet that never chose as listed while it is public", async () => {
    const subject = await mount(verifiedFleet());

    expect(listedToggle(subject)?.props("modelValue")).toBe(true);
  });

  it("shows a private fleet that never chose as unlisted", async () => {
    const subject = await mount(verifiedFleet({ publicFleet: false }));

    expect(listedToggle(subject)?.props("modelValue")).toBe(false);
  });

  it("does not send a choice nobody made", async () => {
    const subject = await mount(verifiedFleet({ publicFleet: false }));

    await save(subject);

    expect(mutateAsync).toHaveBeenCalledOnce();
    expect(mutateAsync.mock.calls[0][0].data).not.toHaveProperty("listed");
  });

  it("follows publicFleet while nobody has chosen, and still sends nothing", async () => {
    const subject = await mount(verifiedFleet({ publicFleet: false }));
    const publicToggle = subject
      .findAllComponents(FormToggle)
      .find((toggle) => toggle.props("name") === "publicFleet")!;

    publicToggle.vm.$emit("update:modelValue", true);
    await flushPromises();

    expect(listedToggle(subject)?.props("modelValue")).toBe(true);

    await save(subject);

    expect(mutateAsync.mock.calls[0][0].data).not.toHaveProperty("listed");
    expect(mutateAsync.mock.calls[0][0].data.publicFleet).toBe(true);
  });

  it("sends the toggle once a manager has touched it", async () => {
    const subject = await mount(verifiedFleet());

    listedToggle(subject)!.vm.$emit("update:modelValue", false);
    await flushPromises();
    await save(subject);

    expect(mutateAsync.mock.calls[0][0].data.listed).toBe(false);
  });

  it("sends the choice once a manager has made it", async () => {
    const subject = await mount(verifiedFleet({ listed: false }));

    await save(subject);

    expect(mutateAsync.mock.calls[0][0].data.listed).toBe(false);
  });

  it("leaves the toggle to managers", async () => {
    const subject = await mount(verifiedFleet(), {
      capabilities: { manageFleet: false },
    } as FleetMember);

    expect(listedToggle(subject)).toBeUndefined();
    expect(subject.find('[data-test="fleet-rsi-profile"]').exists()).toBe(true);
  });

  it("shows the synced RSI values, language names from the browser", async () => {
    const subject = await mount(verifiedFleet());
    const profile = subject.find('[data-test="fleet-rsi-profile"]').text();

    expect(profile).toContain("Piracy");
    expect(profile).toContain("German");
  });
});
