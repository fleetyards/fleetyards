import mitt from "mitt";
import type { AppModalOptions } from "@/shared/components/AppModal/index.vue";

type Events = {
  "open-modal": AppModalOptions;
  "close-modal"?: boolean;
  "prices-update": undefined;
  "commodities-update": undefined;
  "open-privacy-settings"?: boolean;
  "user-update": undefined;
  "fleet-create": undefined;
  "fleet-update": undefined;
};

const AppComlink = mitt<Events>();

export const useComlink = (): typeof AppComlink => AppComlink;
