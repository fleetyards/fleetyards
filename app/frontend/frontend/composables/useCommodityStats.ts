import { type Commodity } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { type HardpointStat } from "@/frontend/composables/useHardpointStats";

/**
 * What the site states about one commodity, labelled and in reading order --
 * the same shape `useComponentStats` and `useEquipmentStats` hand a stats card.
 * A figure the commodity does not carry is left out rather than printed empty.
 */
export const useCommodityStats = (
  commodity: MaybeRefOrGetter<Commodity | undefined>,
) => {
  const { t, tExists, toNumber } = useI18n();

  return computed<HardpointStat[]>(() => {
    const value = toValue(commodity);
    if (!value) return [];

    const type = value.commodityType;
    const typePath = `labels.commodity.types.${type}`;

    return [
      {
        label: t("labels.commodity.commodityType"),
        value: type ? (tExists(typePath) ? t(typePath) : type) : undefined,
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
