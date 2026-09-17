import { computed, toValue, type MaybeRefOrGetter } from "vue";
import {
  HardpointCategoryEnum,
  type Component,
  type Hardpoint,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useHardpointStats,
  type HardpointStat,
} from "@/frontend/composables/useHardpointStats";

// A component's own `category` and the slot vocabulary a hardpoint speaks are
// two different lists. They agree on almost every value, and disagree on the
// one that matters: the game splits thrusters four ways by where they sit on
// the hull, while a thruster component only ever says `thrusters`. Left
// unmapped it matches no branch at all and a thruster renders no stats.
//
// `external_fuel_tanks`, `weapon_mounts`, `emp` and the rest have no component
// category of their own, so they need no entry here.
const CATEGORY_ALIASES: Record<string, HardpointCategoryEnum> = {
  thrusters: HardpointCategoryEnum.MAIN_THRUSTERS,
};

export const hardpointCategoryFor = (
  category: string | undefined | null,
): HardpointCategoryEnum | undefined => {
  if (!category) return undefined;

  const alias = CATEGORY_ALIASES[category];
  if (alias) return alias;

  const known = (Object.values(HardpointCategoryEnum) as string[]).includes(
    category,
  );

  return known ? (category as HardpointCategoryEnum) : undefined;
};

// Power, heat and signature, which every powered item carries and which no
// category branch renders -- they live beside the per-category figures rather
// than inside any one of them. A ship page leaves them out on purpose (a
// hardpoint list would drown in them); a component's own page is exactly where
// they belong.
const usePoweredStats = (
  component: MaybeRefOrGetter<Component | undefined>,
) => {
  const { t, toNumber } = useI18n();

  return computed<HardpointStat[]>(() => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const data = toValue(component)?.typeData as any;
    if (!data) return [];

    const stats: HardpointStat[] = [];
    const push = (key: string, value: unknown, format: string) => {
      if (typeof value !== "number" || !value) return;

      stats.push({
        label: t(`labels.hardpoint.${key}`),
        value: String(toNumber(value, format)),
      });
    };

    push("powerConsumption", data.powerConsumption, "integer");
    push("signatureEm", data.signatureEm, "integer");
    push("signatureIr", data.signatureIr, "integer");

    // A fraction of full draw, so it reads as a percentage rather than "0.4".
    if (typeof data.powerMinimumFraction === "number") {
      stats.push({
        label: t("labels.hardpoint.powerMinimumFraction"),
        value: `${Math.round(data.powerMinimumFraction * 100)}%`,
      });
    }

    return stats;
  });
};

// Every figure the site holds for one component, labelled and ordered, without
// a ship anywhere in the picture.
//
// The per-category work is `useHardpointStats` rather than a second
// implementation of it: it already branches across a dozen categories and its
// labels are already translated in all seven locales. It reads a hardpoint, so
// the component is handed to it as one -- the three ship-level values it
// injects (quantum fuel, the weapon power pool, the power-plant context) are
// all optional there, and the figures depending on them simply do not appear.
export const useComponentStats = (
  component: MaybeRefOrGetter<Component | undefined>,
) => {
  const asHardpoint = computed<Hardpoint | undefined>(() => {
    const value = toValue(component);
    const category = hardpointCategoryFor(value?.category);
    if (!value || !category) return undefined;

    return { category, component: value } as Hardpoint;
  });

  const categoryStats = useHardpointStats(asHardpoint);
  const poweredStats = usePoweredStats(component);

  return computed<HardpointStat[]>(() => [
    ...categoryStats.value,
    ...poweredStats.value,
  ]);
};
