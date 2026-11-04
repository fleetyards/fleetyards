import type {
  MediaFile,
  Model,
  ModelModulePackage,
  Vehicle,
  VehiclePublic,
} from "@/services/fyApi";
import { FleetchartViewpoints } from "@/shared/stores/fleetchart";

export type FleetchartEntry = Vehicle | Model | VehiclePublic;

export const PIXELS_PER_METRE = 4;

export interface FleetchartViewOptions {
  extended?: boolean;
  colored?: boolean;
}

export interface FleetchartShipGeometry {
  length: number;
  height: number;
  imageWidth: number;
  // How tall the current view draws, which can be far less than `height`: that is
  // the tallest of the ship's views, so the box holds when the viewpoint changes.
  imageHeight: number;
}

type ViewName = "angledView" | "frontView" | "portView" | "topView";

const VIEW_BY_VIEWPOINT: Record<FleetchartViewpoints, ViewName> = {
  [FleetchartViewpoints.ANGLED]: "angledView",
  [FleetchartViewpoints.FRONT]: "frontView",
  [FleetchartViewpoints.PORT]: "portView",
  [FleetchartViewpoints.TOP]: "topView",
};

// The front view is not among them: it would stretch a ship's box, and every
// viewpoint has to keep the same box so switching does not move anything.
const SIZING_VIEWS: ViewName[] = ["angledView", "portView", "topView"];

export const modelOf = (entry: FleetchartEntry): Model =>
  (entry as Vehicle).model ?? (entry as Model);

const modulePackageOf = (entry: FleetchartEntry) =>
  (entry as Vehicle).modulePackage as ModelModulePackage | null | undefined;

type MediaLookup = Partial<Record<string, MediaFile | null>>;

const resolveView = (
  entry: FleetchartEntry,
  view: ViewName,
  { extended = false, colored = false }: FleetchartViewOptions,
): MediaFile | undefined => {
  const modulePackageMedia = modulePackageOf(entry)?.media as
    MediaLookup | undefined;
  const modulePackageView = modulePackageMedia?.[view];

  if (view !== "frontView" && modulePackageView) {
    return modulePackageView;
  }

  const media = (modelOf(entry).media ?? {}) as MediaLookup;
  const capitalized = `${view[0].toUpperCase()}${view.slice(1)}`;

  const candidates = [
    extended && colored ? media[`extended${capitalized}Colored`] : undefined,
    extended ? media[`extended${capitalized}`] : undefined,
    colored ? media[`${view}Colored`] : undefined,
    media[view],
  ];

  return candidates.find((candidate) => candidate?.url) ?? undefined;
};

export const viewFor = (
  entry: FleetchartEntry,
  viewpoint: FleetchartViewpoints,
  options: FleetchartViewOptions = {},
) => resolveView(entry, VIEW_BY_VIEWPOINT[viewpoint], options);

export const metricsOf = (entry: FleetchartEntry, extended: boolean) => {
  const { metrics } = modelOf(entry);

  return {
    length:
      (extended
        ? metrics.extendedFleetchartOffsetLength || metrics.extendedLength
        : undefined) ||
      metrics.fleetchartOffsetLength ||
      0,
    beam:
      (extended
        ? metrics.extendedFleetchartOffsetBeam || metrics.extendedBeam
        : undefined) ||
      metrics.fleetchartOffsetBeam ||
      0,
  };
};

// A ship's box in metres, or undefined when there is nothing to draw it from:
// the views have not arrived, or the ship has none.
export const shipGeometry = (
  entry: FleetchartEntry,
  viewpoint: FleetchartViewpoints,
  options: FleetchartViewOptions = {},
): FleetchartShipGeometry | undefined => {
  const sizing = SIZING_VIEWS.map((view) =>
    resolveView(entry, view, options),
  ).filter((view) => view?.width && view?.height) as MediaFile[];

  if (!sizing.length) {
    return undefined;
  }

  const { length, beam } = metricsOf(entry, !!options.extended);
  const maxWidth = Math.max(...sizing.map((view) => view.width || 0));
  const maxHeight = Math.max(...sizing.map((view) => view.height || 0));
  const height = (Math.max(length, beam) * maxHeight) / maxWidth;

  const source = viewFor(entry, viewpoint, options);
  const imageWidth =
    source?.width && source?.height
      ? Math.min((height * source.width) / source.height, length)
      : 0;

  const imageHeight =
    source?.width && source?.height
      ? (imageWidth * source.height) / source.width
      : 0;

  return { length, height, imageWidth, imageHeight };
};

export const shipLabelOf = (entry: FleetchartEntry) => {
  const model = modelOf(entry);
  const modelName = `${model.manufacturer?.code} ${model.name}`;
  const vehicleName = (entry as Vehicle).model ? (entry as Vehicle).name : null;

  return vehicleName
    ? { title: vehicleName, subtitle: modelName }
    : { title: modelName, subtitle: undefined };
};

const FULL_IMAGE_MIN_WIDTH = 1900;
const LARGE_IMAGE_MIN_WIDTH = 900;

export const imageUrlFor = (view: MediaFile, renderedWidth: number) => {
  if (renderedWidth > FULL_IMAGE_MIN_WIDTH) {
    return view.url;
  }

  if (renderedWidth > LARGE_IMAGE_MIN_WIDTH) {
    return view.largeUrl;
  }

  return view.mediumUrl;
};
