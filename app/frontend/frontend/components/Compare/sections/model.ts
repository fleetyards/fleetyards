import { computed, toValue, type MaybeRefOrGetter } from "vue";
import { useCompareFormat } from "@/frontend/components/Compare/format";
import {
  hasRowData,
  valueRows,
  type CompareMetric,
  type CompareSection,
  type CompareTableRow,
} from "@/frontend/components/Compare/types";
import {
  containersOfSize,
  maxContainerSize,
} from "@/frontend/components/CargoGridViewer/capacity";
import { CONTAINER_DEFS } from "@/frontend/components/CargoGridViewer/constants";
import { useI18n } from "@/shared/composables/useI18n";
import {
  HardpointCategoryEnum,
  type ComponentQuantumDrive,
  type Hardpoint,
  type Model,
} from "@/services/fyApi";

// Sections whose subject is the model itself. Combat, Defense, Hull and the loadout
// compare derived stats instead — see ./loadout.
export const useModelSections = (
  models: MaybeRefOrGetter<Model[]>,
  hardpointsFor: (model: Model) => Hardpoint[],
) => {
  const { t } = useI18n();
  const { number, rounded, uec, dollar, text } = useCompareFormat();

  const subjects = () =>
    toValue(models).map((model) => ({ key: model.slug, subject: model }));

  const section = (
    id: string,
    title: string,
    rows: CompareTableRow[],
  ): CompareSection | undefined =>
    hasRowData(rows) ? { id, title, rows } : undefined;

  // ── Views ───────────────────────────────────────────────────────────────────
  // Every silhouette is scaled against the longest ship on screen, so the row reads as
  // a size comparison rather than a strip of thumbnails.
  const viewRow = (
    key: string,
    label: string,
    src: (model: Model) => string | undefined,
  ): CompareTableRow => {
    const list = toValue(models);
    const longest = Math.max(
      ...list.map((model) => model.metrics.fleetchartOffsetLength || 1),
      1,
    );

    return {
      kind: "view",
      key,
      label,
      cells: list.map((model) => ({
        key: model.slug,
        src: src(model),
        alt: `${model.name} — ${label}`,
        widthPercent:
          ((model.metrics.fleetchartOffsetLength || 1) * 100) / longest,
      })),
    };
  };

  const views = computed(() =>
    section("views", t("labels.metrics.views"), [
      viewRow(
        "side-view",
        t("labels.model.sideView"),
        (model) => model.media.sideView?.smallUrl,
      ),
      viewRow(
        "top-view",
        t("labels.model.topView"),
        (model) => model.media.topView?.smallUrl,
      ),
    ]),
  );

  // ── Base ────────────────────────────────────────────────────────────────────
  // Dimensions and mass carry no direction on purpose — a longer or heavier ship is
  // neither better nor worse, and a winner marker there would be an opinion the data
  // does not support.
  const baseMetrics: CompareMetric<Model>[] = [
    {
      key: "manufacturer",
      label: t("model.manufacturer"),
      value: (model) => text(model.manufacturer?.name),
    },
    {
      key: "production-status",
      label: t("model.productionStatus"),
      value: (model) =>
        model.productionStatus
          ? t(`labels.model.productionStatus.${model.productionStatus}`)
          : undefined,
    },
    { key: "focus", label: t("model.focus"), value: (m) => text(m.focus) },
    {
      key: "classification",
      label: t("model.classification"),
      value: (m) => text(m.classificationLabel),
    },
    {
      key: "size",
      label: t("model.size"),
      value: (m) => text(m.metrics.sizeLabel),
    },
    {
      key: "length",
      label: t("model.length"),
      value: (m) => number(m.metrics.length, "distance"),
    },
    {
      key: "beam",
      label: t("model.beam"),
      value: (m) => number(m.metrics.beam, "distance"),
    },
    {
      key: "height",
      label: t("model.height"),
      value: (m) => number(m.metrics.height, "distance"),
    },
    {
      key: "mass",
      label: t("model.mass"),
      value: (m) => number(m.metrics.mass, "weight"),
    },
    {
      key: "cargo",
      label: t("model.cargo"),
      direction: "higher",
      raw: (m) => m.metrics.cargo,
      value: (m) => number(m.metrics.cargo, "cargo"),
    },
    {
      key: "price",
      label: t("model.price"),
      direction: "lower",
      html: true,
      raw: (m) => m.price,
      value: (m) => uec(m.price),
    },
    {
      key: "pledge-price",
      label: t("model.pledgePrice"),
      direction: "lower",
      raw: (m) => m.pledgePrice,
      value: (m) => dollar(m.pledgePrice),
    },
  ];

  const base = computed(() =>
    section(
      "base",
      t("labels.metrics.base"),
      valueRows(baseMetrics, subjects()),
    ),
  );

  // ── Crew ────────────────────────────────────────────────────────────────────
  // Fewer hands needed to fly is the advantage on min crew; more stations supported is
  // the advantage on max.
  const crewMetrics: CompareMetric<Model>[] = [
    {
      key: "min-crew",
      label: t("model.minCrew"),
      direction: "lower",
      raw: (m) => m.crew.min,
      value: (m) => number(m.crew.min, "people"),
    },
    {
      key: "max-crew",
      label: t("model.maxCrew"),
      direction: "higher",
      raw: (m) => m.crew.max,
      value: (m) => number(m.crew.max, "people"),
    },
  ];

  const crew = computed(() =>
    section(
      "crew",
      t("labels.metrics.crew"),
      valueRows(crewMetrics, subjects()),
    ),
  );

  // ── Flight ──────────────────────────────────────────────────────────────────
  const anyGround = (list: Model[]) =>
    list.some((model) => model.metrics.isGroundVehicle);

  const anyFlight = (list: Model[]) =>
    list.some((model) => !model.metrics.isGroundVehicle);

  const speed = (
    key: string,
    label: string,
    pick: (model: Model) => number | undefined,
    visible?: (list: Model[]) => boolean,
  ): CompareMetric<Model> => ({
    key,
    label,
    direction: "higher",
    raw: pick,
    value: (model) => number(pick(model), "speed"),
    visible,
  });

  const rotation = (
    key: string,
    label: string,
    pick: (model: Model) => number | undefined,
  ): CompareMetric<Model> => ({
    key,
    label,
    direction: "higher",
    raw: pick,
    value: (model) => number(pick(model), "rotation"),
    visible: anyFlight,
  });

  const flightMetrics: CompareMetric<Model>[] = [
    speed("scm", t("model.scmSpeed"), (m) => m.speeds.scmSpeed, anyFlight),
    speed(
      "scm-boosted",
      t("model.scmSpeedBoosted"),
      (m) => m.speeds.scmSpeedBoosted,
      anyFlight,
    ),
    speed("max", t("model.maxSpeed"), (m) => m.speeds.maxSpeed, anyFlight),
    speed(
      "reverse-boosted",
      t("model.reverseSpeedBoosted"),
      (m) => m.speeds.reverseSpeedBoosted,
      anyFlight,
    ),
    speed(
      "ground-max",
      t("model.compare.groundMaxSpeed"),
      (m) => m.speeds.groundMaxSpeed,
      anyGround,
    ),
    speed(
      "ground-reverse",
      t("model.compare.groundReverseSpeed"),
      (m) => m.speeds.groundReverseSpeed,
      anyGround,
    ),
    speed(
      "ground-acceleration",
      t("model.groundAcceleration"),
      (m) => m.speeds.groundAcceleration,
      anyGround,
    ),
    rotation("pitch", t("model.pitch"), (m) => m.speeds.pitch),
    rotation("yaw", t("model.yaw"), (m) => m.speeds.yaw),
    rotation("roll", t("model.roll"), (m) => m.speeds.roll),
  ];

  const flight = computed(() =>
    section(
      "flight",
      t("labels.metrics.speed"),
      valueRows(flightMetrics, subjects()),
    ),
  );

  // ── Cargo ───────────────────────────────────────────────────────────────────
  const holdsFor = (model: Model) => model.cargoHolds || [];

  // Prefer the holds we can actually see over the ship-matrix total, the same way the
  // ship page's cargo card does.
  const totalCargo = (model: Model) => {
    const holds = holdsFor(model);

    if (!holds.length) {
      return model.metrics.cargo;
    }

    const sum = holds.reduce((total, hold) => total + (hold.capacity || 0), 0);

    return sum || model.metrics.cargo;
  };

  const cargoMetrics: CompareMetric<Model>[] = [
    {
      key: "cargo-total",
      label: t("model.cargo"),
      direction: "higher",
      raw: totalCargo,
      value: (model) => number(totalCargo(model), "cargo"),
    },
    {
      key: "cargo-max-container",
      label: t("labels.cargoGridViewer.maxContainerSize"),
      direction: "higher",
      raw: (model) => maxContainerSize(holdsFor(model)),
      value: (model) => {
        const size = maxContainerSize(holdsFor(model));

        return size ? `${size} SCU` : undefined;
      },
    },
    ...CONTAINER_DEFS.map<CompareMetric<Model>>((def) => ({
      key: `cargo-container-${def.size}`,
      label: t("labels.compare.containersOfSize", { size: def.size }),
      direction: "higher",
      unit: "×",
      raw: (model) => {
        const holds = holdsFor(model);

        return holds.length ? containersOfSize(holds, def.size) : undefined;
      },
      value: (model) => {
        const count = containersOfSize(holdsFor(model), def.size);

        return count > 0 ? String(count) : undefined;
      },
      // A container size nothing on screen can take is noise, not information.
      visible: (list) =>
        list.some((model) => containersOfSize(holdsFor(model), def.size) > 0),
    })),
  ];

  const cargo = computed(() =>
    section(
      "cargo",
      t("labels.metrics.cargo"),
      valueRows(cargoMetrics, subjects()),
    ),
  );

  // ── Fuel & quantum ──────────────────────────────────────────────────────────
  const findQuantumDrive = (
    hardpoints: Hardpoint[] | undefined,
  ): ComponentQuantumDrive | undefined => {
    for (const hardpoint of hardpoints || []) {
      if (
        hardpoint.category === HardpointCategoryEnum.QUANTUMDRIVE &&
        hardpoint.component?.typeData
      ) {
        return hardpoint.component.typeData as ComponentQuantumDrive;
      }

      const nested = findQuantumDrive(hardpoint.hardpoints);

      if (nested) {
        return nested;
      }
    }

    return undefined;
  };

  // Max jump range on a full tank: quantum fuel (SCU) × 1000 / the drive's per-Gm
  // consumption (mSCU/Gm). Matches erkul.games and spviewer.eu.
  const quantumRange = (model: Model) => {
    const tank = model.metrics.quantumFuelTankSize;
    const consumption = findQuantumDrive(
      hardpointsFor(model),
    )?.quantumFuelConsumption;

    if (!tank || !consumption) {
      return undefined;
    }

    return (tank * 1000) / consumption;
  };

  const crossSection = (model: Model, axis: "x" | "y" | "z") =>
    model.metrics.signatureCrossSection?.[axis];

  const axisMetric = (axis: "x" | "y" | "z"): CompareMetric<Model> => ({
    key: `cross-section-${axis}`,
    label: t(`labels.compare.crossSection.${axis}`),
    // A smaller radar cross-section is harder to detect and harder to hit.
    direction: "lower",
    raw: (model) => crossSection(model, axis),
    value: (model) => number(crossSection(model, axis)),
    visible: (list) => list.some((model) => !!crossSection(model, axis)),
  });

  const fuelMetrics: CompareMetric<Model>[] = [
    {
      key: "hydrogen-fuel",
      label: t("model.hydrogenFuelTankSize"),
      direction: "higher",
      raw: (m) => m.metrics.hydrogenFuelTankSize,
      value: (m) => number(m.metrics.hydrogenFuelTankSize, "cargo"),
    },
    {
      key: "quantum-fuel",
      label: t("model.quantumFuelTankSize"),
      direction: "higher",
      raw: (m) => m.metrics.quantumFuelTankSize,
      value: (m) => number(m.metrics.quantumFuelTankSize, "cargo"),
    },
    {
      key: "quantum-range",
      label: t("labels.hardpoint.quantumDrives.range"),
      unit: "Gm",
      direction: "higher",
      raw: quantumRange,
      value: (model) => rounded(quantumRange(model), "integer"),
    },
    {
      key: "weapon-pool",
      label: t("labels.compare.weaponPoolSize"),
      direction: "higher",
      raw: (m) => m.metrics.weaponPoolSize,
      value: (m) => rounded(m.metrics.weaponPoolSize, "integer"),
    },
    axisMetric("x"),
    axisMetric("y"),
    axisMetric("z"),
  ];

  const fuel = computed(() =>
    section(
      "fuel",
      t("labels.compare.fuelAndQuantum"),
      valueRows(fuelMetrics, subjects()),
    ),
  );

  return { views, base, crew, flight, cargo, fuel };
};
