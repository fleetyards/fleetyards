import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { ref } from "vue";
import { AxiosError } from "axios";

const fetchFleetVehicles = vi.fn();
const createShip = vi.fn();
const displayAlert = vi.fn();

vi.mock("@/services/fyApi", () => ({
  models: vi.fn(),
  fleetVehicles: (...args: unknown[]) => fetchFleetVehicles(...args),
  modelPositions: vi.fn(),
  useModelClassificationsFilters: () => ({ data: ref([]) }),
  useModelFocusFilters: () => ({ data: ref([]) }),
}));

vi.mock("@/frontend/components/Fleets/Missions/useLineupApi", () => ({
  isFlightScope: () => true,
  useLineupApi: () => ({ createShip, updateShip: vi.fn() }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/frontend/composables/usePositionTypeLabel", () => ({
  usePositionTypeLabel: () => (type: string) => type,
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess: vi.fn(), displayAlert }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn() }),
}));

vi.mock("@/shared/components/AppModal/dirty", () => ({
  useModalDirty: vi.fn(),
}));

import ShipModal from "./index.vue";

const mountModal = () =>
  mount(ShipModal, {
    props: {
      fleet: { slug: "black-sun" } as never,
      scope: {
        fleetSlug: "black-sun",
        squadronSlug: "red",
        flightId: "flight-1",
        teamId: "team-1",
      },
    },
    global: {
      stubs: {
        Modal: { template: "<div><slot /><slot name='footer' /></div>" },
        Btn: true,
        BtnGroup: true,
        FormInput: true,
        FormMarkdownEditor: true,
        BaseSelect: {
          name: "BaseSelect",
          props: ["queryFn"],
          template: "<div />",
        },
      },
      directives: { tooltip: {} },
    },
  });

const rejection = (message: string) =>
  new AxiosError("Request failed", "ERR_BAD_REQUEST", undefined, undefined, {
    status: 400,
    data: {
      code: "validation_error.mission_ships.create",
      errors: [
        {
          attribute: "modelId",
          messages: [{ code: "must_be_in_game", message }],
        },
      ],
    },
  } as never);

describe("ShipModal for a flight", () => {
  beforeEach(() => {
    fetchFleetVehicles.mockReset().mockResolvedValue({ items: [] });
    createShip.mockReset();
    displayAlert.mockReset();
  });

  it("offers only the squadron's ships the game has", async () => {
    const wrapper = mountModal();

    await wrapper.findComponent({ name: "BaseSelect" }).props("queryFn")({
      page: 1,
    });

    expect(fetchFleetVehicles).toHaveBeenCalledWith("black-sun", {
      page: "1",
      q: { squadronSlugIn: ["red"], modelInGameEq: true },
    });
  });

  it("says why the ship was refused", async () => {
    createShip.mockRejectedValue(
      rejection("Vehicle is already in this flight"),
    );
    const wrapper = mountModal();

    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalledWith({
      text: "Vehicle is already in this flight",
    });
  });
});
