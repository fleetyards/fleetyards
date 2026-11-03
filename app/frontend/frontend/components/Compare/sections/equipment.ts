import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { useCompareFormat } from "@/frontend/components/Compare/format";
import type { CompareDirection } from "@/frontend/components/Compare/highlights";
import {
  hasRowData,
  valueRows,
  type CompareMetric,
  type CompareSection,
  type CompareTableRow,
} from "@/frontend/components/Compare/types";
import {
  equipmentVocabulary,
  useEquipmentStatReader,
  type EquipmentStatKey,
} from "@/frontend/composables/useEquipmentStats";
import { useI18n } from "@/shared/composables/useI18n";
import type { Equipment } from "@/services/fyApi";

// Rate of fire and volume trade against something else, and the labelled
// figures are not numbers at all, so none of those is marked.
const DIRECTIONS: Partial<Record<EquipmentStatKey, CompareDirection>> = {
  alphaDamage: "higher",
  dps: "higher",
  blastDamage: "higher",
  blastRadius: "higher",
  meleeDamage: "higher",
  tractorForce: "higher",
  tractorRange: "higher",
  healRange: "higher",
  doseRate: "higher",
  repairRate: "higher",
  salvageRate: "higher",
  miningPower: "higher",
  extinguishRange: "higher",
  healthRestored: "higher",
  damageReduction: "higher",
  radiationProtection: "higher",
  radiationScrubRate: "higher",
  gForceTolerance: "higher",
  carryingCapacity: "higher",
  magazineSize: "higher",
  range: "higher",
};

export const useEquipmentSections = (items: MaybeRefOrGetter<Equipment[]>) => {
  const { t } = useI18n();
  const { text } = useCompareFormat();
  const { read, raw } = useEquipmentStatReader();

  const subjects = () =>
    toValue(items).map((item) => ({ key: item.slug, subject: item }));

  const section = (
    id: string,
    title: string,
    rows: CompareTableRow[],
  ): CompareSection | undefined => {
    // A row no item has a figure for is a row of dashes.
    const filled = rows.filter((row) => hasRowData([row]));

    return filled.length ? { id, title, rows: filled } : undefined;
  };

  const identityMetrics: CompareMetric<Equipment>[] = [
    {
      key: "manufacturer",
      label: t("model.manufacturer"),
      value: (item) => text(item.manufacturer?.name),
    },
    {
      key: "item-type",
      label: t("labels.filters.equipment.itemType"),
      value: (item) => text(item.itemTypeLabel ?? item.equipmentTypeLabel),
    },
    {
      key: "sub-type",
      label: t("labels.component.subType"),
      value: (item) => text(item.subTypeLabel),
    },
    {
      key: "slot",
      label: t("labels.filters.equipment.slot"),
      value: (item) => text(item.slotLabel),
    },
    {
      key: "size",
      label: t("labels.hardpoint.size"),
      value: (item) => text(item.size),
    },
    {
      key: "grade",
      label: t("labels.component.grade"),
      value: (item) => text(item.grade),
    },
  ];

  const identity = computed(() =>
    section(
      "identity",
      t("headlines.component.identity"),
      valueRows(identityMetrics, subjects()),
    ),
  );

  // The figures each item's own page leads with, in that page's order. A set
  // holds one type, but the union keeps a stray item's figures on screen too.
  const statKeys = () => {
    const keys: EquipmentStatKey[] = [];

    toValue(items).forEach((item) => {
      const { primary, rest } = equipmentVocabulary(item.equipmentType);

      [...primary, ...rest].forEach((key) => {
        if (!keys.includes(key)) keys.push(key);
      });
    });

    return keys;
  };

  const stats = computed(() =>
    section(
      "metrics",
      t("headlines.component.metrics"),
      valueRows(
        statKeys().map((key): CompareMetric<Equipment> => ({
          key: `stat-${key}`,
          label: t(`labels.equipment.stats.${key}`),
          direction: DIRECTIONS[key],
          raw: (item) => raw(item, key),
          value: (item) => read(item, key),
        })),
        subjects(),
      ),
    ),
  );

  const sections = computed<CompareSection[]>(() =>
    [identity.value, stats.value].filter(
      (entry): entry is CompareSection => !!entry,
    ),
  );

  return { sections };
};
