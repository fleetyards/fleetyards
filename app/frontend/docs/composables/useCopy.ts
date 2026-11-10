import copyText from "@/shared/utils/CopyText";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

export const useCopy = () => {
  const { t } = useI18n();

  const { displayInfo, displayAlert } = useAppNotifications();

  const copy = (text: string) =>
    copyText(text).then(
      () => {
        displayInfo({
          text: t("messages.copy.success"),
        });
      },
      () => {
        displayAlert({
          text: t("messages.copy.failure"),
        });
      },
    );

  return { copy };
};
