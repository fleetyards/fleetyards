import type {
  FleetFleetchartShip,
  FleetchartModel,
  FleetchartViewMedia,
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

// The pictures are merged in once the chart has fetched them.
export type FleetchartSlimModel = FleetchartModel & {
  media?: FleetchartViewMedia;
};

// A fleet ship as the fleetchart endpoint sends it, joined to its model and
// module package on the client.
export type FleetchartShip = Omit<
  FleetFleetchartShip,
  "modelId" | "modulePackageId"
> & {
  model: FleetchartSlimModel;
  modulePackage?: ModelModulePackage;
};

export type FleetchartEntry =
  Vehicle | Model | VehiclePublic | FleetchartShip | FleetchartSlimModel;

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

export const modelOf = (entry: FleetchartEntry): Model | FleetchartSlimModel =>
  (entry as Vehicle | FleetchartShip).model ?? (entry as Model);

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

// A state without a picture of this view borrows the flight one, which only stays at
// the chart's scale at the flight size.
const stateOfPicture = (
  entry: FleetchartEntry,
  view: ViewName,
  picture: MediaFile,
  state: FleetchartShipStates,
) => {
  const media = (modelOf(entry).media ?? {}) as MediaLookup;
  const name = `${state}${view[0].toUpperCase()}${view.slice(1)}`;

  return picture === media[name] || picture === media[`${name}Colored`]
    ? state
    : FleetchartShipStates.FLIGHT;
};

// How far the angled cameras are turned, for a picture not yet measured from the
// ship's outline. Taken as an ellipse of length by beam, as a ship does not fill the
// corners of a box unless its wings are spread.
const ANGLED_VIEW_SHARES: Partial<
  Record<ViewName, { length: number; beam: number }>
> = {
  angledView: { length: 0.707, beam: 0.707 },
  angledRearView: { length: 0.623, beam: 0.783 },
};

const MEASURED_EXTENTS: Partial<Record<ViewName, "angled" | "angledRear">> = {
  angledView: "angled",
  angledRearView: "angledRear",
};

// Seen from ahead or behind a picture is as wide as the ship's beam, and from the side
// or above as wide as its length, however tall the picture is.
const pictureWidth = (
  entry: FleetchartEntry,
  view: ViewName,
  picture: MediaFile,
  state: FleetchartShipStates,
) => {
  const pictureState = stateOfPicture(entry, view, picture, state);
  const { length, beam } = metricsOf(entry, pictureState);
  const measured = MEASURED_EXTENTS[view];
  const extent =
    measured &&
    (modelOf(entry).media as FleetchartViewMedia | undefined)?.angledExtents?.[
      pictureState
    ]?.[measured];
  const shares = ANGLED_VIEW_SHARES[view];

  if (extent) {
    return length * extent;
  }

  if ((view === "frontView" || view === "rearView") && beam) {
    return beam;
  }

  return shares && beam
    ? Math.hypot(shares.length * length, shares.beam * beam)
    : length;
};

// A ship's box in metres, or undefined when there is nothing to draw it from:
// the views have not arrived, or the ship has none.
export const shipGeometry = (
  entry: FleetchartEntry,
  viewpoint: FleetchartViewpoints,
  options: FleetchartViewOptions = {},
): FleetchartShipGeometry | undefined => {
  const state = options.state ?? FleetchartShipStates.FLIGHT;

  const drawnSize = (view: ViewName, picture?: MediaFile) => {
    if (!picture?.width || !picture?.height) {
      return undefined;
    }

    const width = pictureWidth(entry, view, picture, state);

    return { width, height: (width * picture.height) / picture.width };
  };

  const sizing = SIZING_VIEWS.flatMap((view) => {
    const size = drawnSize(view, resolveView(entry, view, options));

    return size ? [size] : [];
  });

  if (!sizing.length) {
    return undefined;
  }

  const { length } = metricsOf(entry, state);
  const drawn = drawnSize(
    VIEW_BY_VIEWPOINT[viewpoint],
    viewFor(entry, viewpoint, options),
  );
  const imageWidth = drawn?.width ?? 0;
  const imageHeight = drawn?.height ?? 0;

  return {
    length,
    height: Math.max(imageHeight, ...sizing.map(({ height }) => height)),
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
