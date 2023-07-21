import mitt from "mitt";
import type { AppModalOptions } from "@/shared/components/AppModal/index.vue";

type Events = {
  "open-modal": AppModalOptions;
  "close-modal": boolean;
};

const AppComlink = mitt<Events>();

export const useComlink = (): typeof AppComlink => AppComlink;
