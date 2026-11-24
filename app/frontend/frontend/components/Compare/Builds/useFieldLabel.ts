import {
  fieldKey,
  readableField,
} from "@/frontend/components/Compare/Builds/format";
import { useI18n } from "@/shared/composables/useI18n";

export const useFieldLabel = () => {
  const { t, tExists } = useI18n();

  return (field: string) => {
    const key = `labels.buildDiff.fields.${fieldKey(field)}`;

    return tExists(key) ? t(key) : readableField(field);
  };
};
