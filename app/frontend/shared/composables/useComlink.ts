import { type AppModalOptions } from "@/shared/components/AppModal/index.vue";
import { type AppConfirmOptions } from "@/shared/components/AppConfirm/types";
import { type FleetMember, type HangarGroup } from "@/services/fyApi";
import { createNanoEvents } from "nanoevents";

type Events = {
  "open-modal": () => AppModalOptions;
  "show-confirm": () => AppConfirmOptions;
  "hide-confirm": () => void;
  "close-modal"?: () => boolean;
  "prices-update": () => void;
  "commodities-update": () => void;
  "open-privacy-settings"?: () => boolean;
  "user-update": () => void | Promise<unknown>;
  "fleet-create": () => void;
  "fleet-update": () => void;
  "fleetchart-toggle-status": () => void;
  "fleet-member-invited": () => FleetMember;
  "fleet-member-update": () => void;
  "access-confirmed": () => void;
  "access-confirmation-required": () => void;
  "vehicle-save"?: () => string;
  "vehicle-destroy"?: () => string;
  "hangar-change": () => void;
  "hangar-delete-all": () => void;
  "hangar-sync-finished": () => void;
  "hangar-group-save": () => void;
  "hangar-group-delete": () => HangarGroup;
};

const AppComlink = createNanoEvents<Events>();

export const useComlink = (): typeof AppComlink => AppComlink;
