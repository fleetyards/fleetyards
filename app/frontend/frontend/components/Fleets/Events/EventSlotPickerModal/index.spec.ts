import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";
import { ref } from "vue";
import { AxiosError } from "axios";

const assignMutation = vi.fn();
const displayAlert = vi.fn();
const emitted = vi.hoisted(() => ({ value: [] as string[] }));

vi.mock("@/services/fyApi", () => ({
  useAssignFleetEventSignup: () => ({
    mutateAsync: assignMutation,
    isPending: ref(false),
  }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess: vi.fn(), displayAlert }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({
    emit: (name: string) => emitted.value.push(name),
    on: vi.fn(),
  }),
}));

import EventSlotPickerModal from "./index.vue";

const mountModal = () =>
  mount(EventSlotPickerModal, {
    props: {
      fleet: { slug: "black-sun" } as never,
      event: {
        teams: [
          {
            id: "team-1",
            title: "Alpha",
            slots: [{ id: "slot-1", title: "Pilot" }],
          },
        ],
      } as never,
      signup: { id: "signup-1", user: { username: "rook" } } as never,
    },
    global: {
      stubs: {
        Modal: { template: "<div><slot /></div>" },
        Btn: { template: "<button><slot /></button>" },
        Pill: true,
      },
      directives: { tooltip: {} },
    },
  });

const rejection = (message: string) =>
  new AxiosError("Request failed", "ERR_BAD_REQUEST", undefined, undefined, {
    status: 400,
    data: {
      code: "validation_error.fleet_event_signups.update",
      errors: [
        {
          attribute: "fleetEventSlotId",
          messages: [{ code: "required", message }],
        },
      ],
    },
  } as never);

describe("EventSlotPickerModal", () => {
  beforeEach(() => {
    assignMutation.mockReset();
    displayAlert.mockReset();
    emitted.value = [];
  });

  it("shows the server's reason and refetches the event when an assign fails", async () => {
    assignMutation.mockRejectedValue(rejection("Slot no longer exists"));

    await mountModal().find("button").trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalledWith({
      text: "Slot no longer exists",
    });
    expect(emitted.value).toEqual([
      "fleet-event-signup-changed",
      "close-modal",
    ]);
  });

  it("keeps the picker open for a retry without a validation error", async () => {
    assignMutation.mockRejectedValue(new Error("Network Error"));

    await mountModal().find("button").trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalledWith({
      text: "messages.fleets.eventSignup.update.failure",
    });
    expect(emitted.value).toEqual([]);
  });
});
