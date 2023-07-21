import type { App } from "vue";
import { useNoty } from "@/shared/composables/useNoty";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

export interface NotyPluginOptions extends ReturnType<typeof useNoty> {}

export default {
  install: (app: App<Element>, i18nComposable: () => I18nPluginOptions) => {
    const { t } = i18nComposable();

    const {
      displaySuccess,
      displayInfo,
      displayWarning,
      displayAlert,
      displayConfirm,
      requestBrowserPermission,
    } = useNoty(t);

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
