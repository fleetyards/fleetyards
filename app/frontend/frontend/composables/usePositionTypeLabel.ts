import { useI18n } from "@/shared/composables/useI18n";

// The API sends the enum value, so a turret seat read TURRET_GUNNER while the
// label uppercased it, and turret_gunner once it no longer did. Unmapped values
// still read as words.
export const usePositionTypeLabel = () => {
  const { t, tExists } = useI18n();

  return (type?: string | null) => {
    if (!type) return null;

    const key = `labels.modelPosition.types.${type}`;

    return tExists(key) ? t(key) : type.replace(/_/g, " ");
  };
};
