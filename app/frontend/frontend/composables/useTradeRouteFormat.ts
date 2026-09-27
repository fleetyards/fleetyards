import { useI18n } from "@/shared/composables/useI18n";
import { type Terminal, type TradeRoute } from "@/services/fyApi";

/**
 * The wording a run shares between the best-run card and the rows below it.
 */
export const useTradeRouteFormat = () => {
  const { t, toNumber, timeDistance } = useI18n();

  const figure = (value?: number | null) =>
    value == null ? "" : String(toNumber(Math.round(value), "integer"));

  // Where the terminal sits, most specific first: the station, city or outpost
  // is what a pilot sets a course for.
  const place = (terminal: Terminal) =>
    terminal.spaceStation ||
    terminal.city ||
    terminal.outpost ||
    terminal.moon ||
    terminal.planet ||
    terminal.orbit;

  const location = (terminal: Terminal) =>
    [
      terminal.starSystem,
      place(terminal) !== terminal.name ? place(terminal) : undefined,
    ]
      .filter(Boolean)
      .join(" · ");

  // A run is only as fresh as its older price, and one with a price of unknown
  // age is of unknown age.
  const pricesAge = (route: TradeRoute) => {
    if (!route.originPriceUpdatedAt || !route.destinationPriceUpdatedAt) {
      return undefined;
    }

    return timeDistance(
      [route.originPriceUpdatedAt, route.destinationPriceUpdatedAt].sort()[0],
    );
  };

  const limitLabel = (route: TradeRoute) =>
    route.loadLimit
      ? t(`labels.tradeRoutes.loadLimits.${route.loadLimit}`)
      : undefined;

  return { figure, place, location, pricesAge, limitLabel };
};
