import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";

type FormErrors = Record<string, string[]>;

export const useFormFeedback = () => {
  const { t } = useI18n();
  const { displaySuccess, displayAlert } = useAppNotifications();

  const created = () =>
    displaySuccess({ text: t("messages.admin.form.created") });

  const updated = () =>
    displaySuccess({ text: t("messages.admin.form.updated") });

  const failed = (error: unknown, setErrors?: (errors: FormErrors) => void) => {
    const { message, formErrors } = validationErrorFrom(error);

    setErrors?.(formErrors);

    displayAlert({ text: message || t("errors.generic") });
  };

  return { created, updated, failed };
};
