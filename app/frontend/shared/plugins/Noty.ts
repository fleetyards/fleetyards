import type { App } from "vue";
import { useNoty } from "@/shared/composables/useNoty";
import { useI18n } from "@/shared/composables/useI18n";

export type NotyPluginOptions = ReturnType<typeof useNoty>;

export default {
  install: (app: App<Element>) => {
    const { t } = useI18n();

    const {
      displaySuccess,
      displayInfo,
      displayWarning,
      displayAlert,
      displayConfirm,
      requestBrowserPermission,
    } = useNoty();

    app.provide<NotyPluginOptions>("noty", {
      displaySuccess,
      displayInfo,
      displayWarning,
      displayAlert,
      displayConfirm,
      requestBrowserPermission,
    });
  },
};
