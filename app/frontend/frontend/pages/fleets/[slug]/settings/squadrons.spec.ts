import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import type { Fleet, FleetMember } from "@/services/fyApi";
import Component from "./squadrons.vue";

const updateFleet = vi.hoisted(() => vi.fn());
const rolesQueryEnabled = vi.hoisted(() => ({ value: undefined as unknown }));

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useUpdateFleet: () => ({ mutateAsync: updateFleet }),
    useFleetSquadronRoles: (
      _slug: unknown,
      options: { query: { enabled: { value: boolean } } },
    ) => {
      rolesQueryEnabled.value = options.query.enabled.value;
      return { data: ref([]), isLoading: ref(false) };
    },
  };
});

let wrapper: VueWrapper | undefined;

beforeEach(() => {
  updateFleet.mockResolvedValue({});
});

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  updateFleet.mockReset();
});

const mount = async (
  squadronsEnabled: boolean,
  capabilities: Record<string, boolean>,
) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: {
      fleet: { slug: "maru", name: "Maru", squadronsEnabled } as Fleet,
      membership: { capabilities } as unknown as FleetMember,
    },
  });

  return wrapper;
};

const toggleInput = (subject: VueWrapper) =>
  subject.find('[data-test="settings-squadrons-enabled"] input');

describe("FleetSettingsSquadronsPage", () => {
  // Switched off, the squadron pages are gone, so this is the one place the
  // switch can live.
  it("offers the switch while squadrons are off, and no ranks", async () => {
    const subject = await mount(false, { enableSquadrons: true });

    expect(toggleInput(subject).exists()).toBe(true);
    expect(rolesQueryEnabled.value).toBe(false);
  });

  it("saves the switch as soon as it is flipped", async () => {
    const subject = await mount(false, { enableSquadrons: true });

    await toggleInput(subject).setValue(true);
    await flushPromises();

    expect(updateFleet).toHaveBeenCalledWith({
      slug: "maru",
      data: { squadronsEnabled: true },
    });
  });

  it("disables the switch for a reader who may not change the fleet", async () => {
    const subject = await mount(true, { manageSquadrons: true });

    expect(toggleInput(subject).attributes("disabled")).toBeDefined();
    expect(rolesQueryEnabled.value).toBe(true);
  });
});
