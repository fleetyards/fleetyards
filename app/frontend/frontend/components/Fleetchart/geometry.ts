import type {
  MediaFile,
  Model,
  ModelModulePackage,
  Vehicle,
  VehiclePublic,
} from "@/services/fyApi";
import {
  FleetchartShipStates,
  FleetchartViewpoints,
} from "@/shared/stores/fleetchart";

export type FleetchartEntry = Vehicle | Model | VehiclePublic;

export const PIXELS_PER_METRE = 4;

export interface FleetchartViewOptions {
  state?: FleetchartShipStates;
  colored?: boolean;
}

export interface FleetchartShipGeometry {
  length: number;
  height: number;
  imageWidth: number;
  // How tall the current view draws, which can be far less than `height`: that is
  // the tallest of the ship's views, so the box holds when the viewpoint changes.
  imageHeight: number;
  // A front or rear view of a ship wider than it is long is wider than its length.
  frameWidth: number;
}

type ViewName =
  | "angledRearView"
  | "angledView"
  | "bottomView"
  | "frontView"
  | "portView"
  | "rearView"
  | "starboardView"
  | "topView";

const VIEW_BY_VIEWPOINT: Record<FleetchartViewpoints, ViewName> = {
  [FleetchartViewpoints.ANGLED]: "angledView",
  [FleetchartViewpoints.FRONT]: "frontView",
  [FleetchartViewpoints.PORT]: "portView",
  [FleetchartViewpoints.TOP]: "topView",
  [FleetchartViewpoints.ANGLED_REAR]: "angledRearView",
  [FleetchartViewpoints.BOTTOM]: "bottomView",
  [FleetchartViewpoints.REAR]: "rearView",
  [FleetchartViewpoints.STARBOARD]: "starboardView",
};

// The front view is not among them: it would stretch a ship's box, and outside the
// layouts that fit each view tightly, a ship's box should hold between viewpoints.
const SIZING_VIEWS: ViewName[] = ["angledView", "portView", "topView"];

export const modelOf = (entry: FleetchartEntry): Model =>
  (entry as Vehicle).model ?? (entry as Model);

const modulePackageOf = (entry: FleetchartEntry) =>
  (entry as Vehicle).modulePackage as ModelModulePackage | null | undefined;

type MediaLookup = Partial<Record<string, MediaFile | null>>;

const resolveView = (
  entry: FleetchartEntry,
  view: ViewName,
  {
    state = FleetchartShipStates.FLIGHT,
    colored = false,
  }: FleetchartViewOptions,
): MediaFile | undefined => {
  const modulePackageMedia = modulePackageOf(entry)?.media as
    MediaLookup | undefined;
  const modulePackageView = modulePackageMedia?.[view];

  if (view !== "frontView" && modulePackageView) {
    return modulePackageView;
  }

  const media = (modelOf(entry).media ?? {}) as MediaLookup;
  const capitalized = `${view[0].toUpperCase()}${view.slice(1)}`;

  const stateView =
    state === FleetchartShipStates.FLIGHT
      ? undefined
      : `${state}${capitalized}`;

  const candidates = [
    stateView && colored ? media[`${stateView}Colored`] : undefined,
    stateView ? media[stateView] : undefined,
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

// Whether a ship has any picture of its own for a state.
export const hasStateViews = (
  entry: FleetchartEntry,
  state: FleetchartShipStates,
) => {
  if (state === FleetchartShipStates.FLIGHT) {
    return true;
  }

  const media = (modelOf(entry).media ?? {}) as MediaLookup;

  return Object.values(VIEW_BY_VIEWPOINT).some((view) => {
    const name = `${state}${view[0].toUpperCase()}${view.slice(1)}`;

    return media[name]?.url || media[`${name}Colored`]?.url;
  });
};

// A ship with no picture of a state is drawn from its flight picture, which has to
// keep its flight size to stay at the chart's scale.
export const metricsOf = (
  entry: FleetchartEntry,
  state: FleetchartShipStates = FleetchartShipStates.FLIGHT,
) => {
  const { metrics } = modelOf(entry);
  const flight = {
    length: metrics.fleetchartOffsetLength || 0,
    beam: metrics.fleetchartOffsetBeam || 0,
  };

  if (!hasStateViews(entry, state)) {
    return flight;
  }

  if (state === FleetchartShipStates.EXTENDED) {
    return {
      length:
        metrics.extendedFleetchartOffsetLength ||
        metrics.extendedLength ||
        flight.length,
      beam:
        metrics.extendedFleetchartOffsetBeam ||
        metrics.extendedBeam ||
        flight.beam,
    };
  }

  if (state === FleetchartShipStates.LANDED) {
    return {
      length:
        metrics.landedFleetchartOffsetLength ||
        metrics.landedLength ||
        flight.length,
      beam:
        metrics.landedFleetchartOffsetBeam || metrics.landedBeam || flight.beam,
    };
  }

  return flight;
};

// Seen from ahead or behind, a ship's width on screen is its beam, not its length.
const BEAM_VIEWS: FleetchartViewpoints[] = [
  FleetchartViewpoints.FRONT,
  FleetchartViewpoints.REAR,
];

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

  const { length, beam } = metricsOf(entry, options.state);
  const maxWidth = Math.max(...sizing.map((view) => view.width || 0));
  const maxHeight = Math.max(...sizing.map((view) => view.height || 0));
  const height = (Math.max(length, beam) * maxHeight) / maxWidth;

  const source = viewFor(entry, viewpoint, options);
  const fitted =
    source?.width && source?.height
      ? Math.min((height * source.width) / source.height, length)
      : 0;
  const imageWidth =
    fitted && beam && BEAM_VIEWS.includes(viewpoint) ? beam : fitted;

  const imageHeight =
    source?.width && source?.height
      ? (imageWidth * source.height) / source.width
      : 0;

  return {
    length,
    height: Math.max(height, imageHeight),
    imageWidth,
    imageHeight,
    frameWidth: Math.max(length, imageWidth),
  };
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
