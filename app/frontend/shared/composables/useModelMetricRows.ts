import type { Model } from "@/services/fyApi";

export type MetricRow = {
  label: string;
  value: string;
  // Pre-formatted markup (the UEC price), rendered with v-html and tooltipped.
  html?: boolean;
};

export type MetricRowGroup = {
  rows: MetricRow[];
  // Dimensions and price sit two-up; the summary rows run full width.
  split?: boolean;
};

/*
 * Which metric rows a model has, for the ship card's expanded details and the
 * embed's card. Shared because the surfaces resolve their own translations - the
 * embed ships 16K of `en` against the frontend's 1.4M of eight locales, so it
 * cannot import the frontend's `useI18n` - while the rules about which figures
 * are meaningful must not diverge between them.
 */
type I18nHelpers = {
  t: (scope: string) => string;
  toNumber: (value: unknown, unit?: string) => string;
  toUEC: (value: unknown) => string;
};

export const useModelMetricRows = (
  model: () => Model,
  { t, toNumber, toUEC }: I18nHelpers,
) => {
  const crew = computed(() => {
    let { min, max } = model().crew;

    if (min && min <= 0) {
      min = undefined;
    }

    if (max && max <= 0) {
      max = undefined;
    }

    if (min === max) {
      return toNumber(model().crew.min, "people");
    }

    return toNumber([min, max].filter((item) => item).join(" - "), "people");
  });

  // Ship-matrix speeds are not meaningful, so they are only shown for models
  // whose figures come from the game files. isGroundVehicle rather than a
  // classification check, matching FlightMetrics: a ground vehicle reports one
  // speed, everything else reports two.
  //
  // Both figures share one row - SCM and max are read as a pair, and two rows
  // for one measurement crowded a summary that is only three or four rows long.
  // The unit sits on the second value only, since it applies to both.
  const speeds = computed<MetricRow[]>(() => {
    if (!model().inGame) {
      return [];
    }

    const { groundMaxSpeed, scmSpeed, maxSpeed } = model().speeds;

    if (model().metrics.isGroundVehicle) {
      return [
        { label: t("model.speed"), value: toNumber(groundMaxSpeed, "speed") },
      ];
    }

    return [
      {
        label: t("model.speed"),
        value: `${t("model.scm")} ${toNumber(scmSpeed)} / ${t("model.max")} ${toNumber(maxSpeed, "speed")}`,
      },
    ];
  });

  const summary = computed<MetricRow[]>(() => {
    const rows: MetricRow[] = [];

    if (model().focus) {
      rows.push({ label: t("model.focus"), value: model().focus as string });
    }

    if (model().crew.min || model().crew.max) {
      rows.push({ label: t("model.crew"), value: crew.value });
    }

    return [...rows, ...speeds.value];
  });

  const dimensions = computed<MetricRow[]>(() => {
    const { length, beam, height, mass, cargo } = model().metrics;

    const rows: MetricRow[] = [
      { label: t("model.length"), value: toNumber(length, "distance") },
      { label: t("model.beam"), value: toNumber(beam, "distance") },
      { label: t("model.height"), value: toNumber(height, "distance") },
      { label: t("model.mass"), value: toNumber(mass, "weight") },
      { label: t("model.cargo"), value: toNumber(cargo, "cargo") },
    ];

    if (model().price) {
      rows.push({
        label: t("model.price"),
        value: toUEC(model().price),
        html: true,
      });
    }

    return rows;
  });

  const groups = computed<MetricRowGroup[]>(() => [
    { rows: summary.value },
    { rows: dimensions.value, split: true },
  ]);

  return { groups };
};
