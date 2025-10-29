import { type AppModalOptions } from "@/shared/components/AppModal/index.vue";
import { type AppConfirmOptions } from "@/shared/components/AppConfirm/types";
import { type FleetMember, type HangarGroup } from "@/services/fyApi";
import { createNanoEvents } from "nanoevents";

type Events = {
  "open-modal": (options: AppModalOptions) => void | Promise<unknown>;
  "show-confirm": (options: AppConfirmOptions) => void | Promise<unknown>;
  "hide-confirm": () => void | Promise<unknown>;
  "close-modal": (force?: boolean) => void | Promise<unknown>;
  "prices-update": () => void | Promise<unknown>;
  "commodities-update": () => void | Promise<unknown>;
  "open-privacy-settings": (force?: boolean) => void | Promise<unknown>;
  "user-update": () => void | Promise<unknown>;
  "fleet-create": () => void | Promise<unknown>;
  "fleet-update": () => void | Promise<unknown>;
  "fleetchart-toggle-status": () => void | Promise<unknown>;
  "fleet-member-invited": (member: FleetMember) => void | Promise<unknown>;
  "fleet-member-update": () => void | Promise<unknown>;
  "access-confirmed": () => void | Promise<unknown>;
  "access-confirmation-required": () => void | Promise<unknown>;
  "vehicle-save": (vehicleId?: string) => void | Promise<unknown>;
  "vehicle-destroy": (vehicleId?: string) => void | Promise<unknown>;
  "hangar-change": () => void | Promise<unknown>;
  "hangar-delete-all": () => void | Promise<unknown>;
  "hangar-sync-finished": () => void | Promise<unknown>;
  "hangar-group-save": () => void | Promise<unknown>;
  "hangar-group-delete": (group: HangarGroup) => void | Promise<unknown>;
};

const AppComlink = createNanoEvents<Events>();

export const useComlink = (): typeof AppComlink => AppComlink;
