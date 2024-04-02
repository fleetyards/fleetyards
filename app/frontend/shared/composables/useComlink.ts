import mitt from "mitt";
import type { AppModalOptions } from "@/shared/components/AppModal/index.vue";
import type { FleetMember } from "@/services/fyApi";

type Events = {
  "open-modal": AppModalOptions;
  "close-modal"?: boolean;
  "prices-update": undefined;
  "commodities-update": undefined;
  "open-privacy-settings"?: boolean;
  "user-update": undefined;
  "fleet-create": undefined;
  "fleet-update": undefined;
  "fleetchart-toggle-status": undefined;
  "fleet-member-invited": FleetMember;
  "fleet-member-update": undefined;
  "access-confirmed": undefined;
  "access-confirmation-required": undefined;
  "vehicle-save": undefined;
  "vehicles-delete-all": undefined;
  "hangar-sync-finished": undefined;
  "hangar-group-save": undefined;
  "hangar-group-delete": undefined;
};

const AppComlink = mitt<Events>();

export const useComlink = (): typeof AppComlink => AppComlink;
