import { type Commodity } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";

/**
 * What the site states about one commodity, labelled and in reading order --
 * the same shape `useComponentStats` and `useEquipmentStats` hand a stats card.
 * A figure the commodity does not carry is left out rather than printed empty.
 */
export const useCommodityTypeLabel = (
  commodity: MaybeRefOrGetter<Commodity | undefined>,
) => {
  const { t, tExists } = useI18n();

  return computed(() => {
    const type = toValue(commodity)?.commodityType;
    if (!type) return undefined;

    const path = `labels.commodity.types.${type}`;

    return tExists(path) ? t(path) : type;
  });
};

type Options = {
  // Off where the type is already named, such as a hover card's eyebrow.
  withType?: MaybeRefOrGetter<boolean>;
};

export const useCommodityStats = (
  commodity: MaybeRefOrGetter<Commodity | undefined>,
  options: Options = {},
) => {
  const { t, toNumber } = useI18n();

  const typeLabel = useCommodityTypeLabel(commodity);

  return computed<HardpointStat[]>(() => {
    const value = toValue(commodity);
    if (!value) return [];

    return [
      {
        label: t("labels.commodity.commodityType"),
        value: toValue(options.withType ?? true) ? typeLabel.value : undefined,
      },
      {
        // Every size the game packages it in, from the hand-carried forms below
        // one SCU up to the 32 freight crates.
        label: t("labels.commodity.containerSizes"),
        value: value.containerSizes?.length
          ? value.containerSizes.map((size) => toNumber(size)).join(" · ")
          : undefined,
        wide: true,
      },
      {
        // Only the counted ones have a single figure: a bulk commodity's unit
        // is a crate, sold in seven sizes, so there is no one volume to state.
        label: t("labels.commodity.pieceVolume"),
        value:
          value.pieceVolume != null
            ? String(toNumber(value.pieceVolume))
            : undefined,
      },
      {
        label: t("labels.commodity.consumable"),
        value: value.consumable ? t("labels.true") : undefined,
      },
    ].filter((stat): stat is HardpointStat => Boolean(stat.value));
  });
};
