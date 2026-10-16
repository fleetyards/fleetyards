import { type MaybeRefOrGetter } from "vue";
import type {
  MediaFile,
  Model,
  ModelMedia,
  ModelMetrics,
} from "@/services/fyApi";

// The three states a ship is held in. `flight` is the ship as it flies and is
// the only one every model has; the other two are uploaded per hull, and their
// dimensions are read off their own holo by MeasureHoloJob rather than typed.
export enum ModelStateEnum {
  FLIGHT = "flight",
  EXTENDED = "extended",
  LANDED = "landed",
}

export enum ModelViewEnum {
  ANGLED = "angled",
  TOP = "top",
  FRONT = "front",
  SIDE = "side",
  ANGLED_REAR = "angledRear",
  BOTTOM = "bottom",
  REAR = "rear",
  STARBOARD = "starboard",
}

// The order the selector offers them in, and the order a fallback walks back to.
export const MODEL_STATES = [
  ModelStateEnum.FLIGHT,
  ModelStateEnum.EXTENDED,
  ModelStateEnum.LANDED,
] as const;

export const MODEL_VIEWS = [
  ModelViewEnum.ANGLED,
  ModelViewEnum.TOP,
  ModelViewEnum.FRONT,
  ModelViewEnum.SIDE,
] as const;

// The same ship seen from behind and below. Only the detail endpoint carries
// these, so a ship from a list never has them.
export const MODEL_REAR_VIEWS = [
  ModelViewEnum.ANGLED_REAR,
  ModelViewEnum.BOTTOM,
  ModelViewEnum.REAR,
  ModelViewEnum.STARBOARD,
] as const;

const ALL_MODEL_VIEWS = [...MODEL_VIEWS, ...MODEL_REAR_VIEWS];

type ViewKeys = { regular: keyof ModelMedia; colored: keyof ModelMedia };

type StateMedia = {
  holo: keyof ModelMedia;
  holoLite: keyof ModelMedia;
  views: Record<ModelViewEnum, ViewKeys>;
};

type StateMetrics = {
  length: keyof ModelMetrics;
  beam: keyof ModelMetrics;
  height: keyof ModelMetrics;
  fleetchartLength: keyof ModelMetrics;
  fleetchartBeam: keyof ModelMetrics;
};

// Written out rather than built from a prefix: the keys are what the generated
// client declares, so a typo is a type error here instead of an undefined at
// runtime.
const STATE_MEDIA: Record<ModelStateEnum, StateMedia> = {
  [ModelStateEnum.FLIGHT]: {
    holo: "holo",
    holoLite: "holoLite",
    views: {
      [ModelViewEnum.ANGLED]: {
        regular: "angledView",
        colored: "angledViewColored",
      },
      [ModelViewEnum.TOP]: { regular: "topView", colored: "topViewColored" },
      [ModelViewEnum.FRONT]: {
        regular: "frontView",
        colored: "frontViewColored",
      },
      [ModelViewEnum.SIDE]: { regular: "sideView", colored: "sideViewColored" },
      [ModelViewEnum.ANGLED_REAR]: {
        regular: "angledRearView",
        colored: "angledRearViewColored",
      },
      [ModelViewEnum.BOTTOM]: {
        regular: "bottomView",
        colored: "bottomViewColored",
      },
      [ModelViewEnum.REAR]: {
        regular: "rearView",
        colored: "rearViewColored",
      },
      [ModelViewEnum.STARBOARD]: {
        regular: "starboardView",
        colored: "starboardViewColored",
      },
    },
  },
  [ModelStateEnum.EXTENDED]: {
    holo: "extendedHolo",
    holoLite: "extendedHoloLite",
    views: {
      [ModelViewEnum.ANGLED]: {
        regular: "extendedAngledView",
        colored: "extendedAngledViewColored",
      },
      [ModelViewEnum.TOP]: {
        regular: "extendedTopView",
        colored: "extendedTopViewColored",
      },
      [ModelViewEnum.FRONT]: {
        regular: "extendedFrontView",
        colored: "extendedFrontViewColored",
      },
      [ModelViewEnum.SIDE]: {
        regular: "extendedSideView",
        colored: "extendedSideViewColored",
      },
      [ModelViewEnum.ANGLED_REAR]: {
        regular: "extendedAngledRearView",
        colored: "extendedAngledRearViewColored",
      },
      [ModelViewEnum.BOTTOM]: {
        regular: "extendedBottomView",
        colored: "extendedBottomViewColored",
      },
      [ModelViewEnum.REAR]: {
        regular: "extendedRearView",
        colored: "extendedRearViewColored",
      },
      [ModelViewEnum.STARBOARD]: {
        regular: "extendedStarboardView",
        colored: "extendedStarboardViewColored",
      },
    },
  },
  [ModelStateEnum.LANDED]: {
    holo: "landedHolo",
    holoLite: "landedHoloLite",
    views: {
      [ModelViewEnum.ANGLED]: {
        regular: "landedAngledView",
        colored: "landedAngledViewColored",
      },
      [ModelViewEnum.TOP]: {
        regular: "landedTopView",
        colored: "landedTopViewColored",
      },
      [ModelViewEnum.FRONT]: {
        regular: "landedFrontView",
        colored: "landedFrontViewColored",
      },
      [ModelViewEnum.SIDE]: {
        regular: "landedSideView",
        colored: "landedSideViewColored",
      },
      [ModelViewEnum.ANGLED_REAR]: {
        regular: "landedAngledRearView",
        colored: "landedAngledRearViewColored",
      },
      [ModelViewEnum.BOTTOM]: {
        regular: "landedBottomView",
        colored: "landedBottomViewColored",
      },
      [ModelViewEnum.REAR]: {
        regular: "landedRearView",
        colored: "landedRearViewColored",
      },
      [ModelViewEnum.STARBOARD]: {
        regular: "landedStarboardView",
        colored: "landedStarboardViewColored",
      },
    },
  },
};

const STATE_METRICS: Record<ModelStateEnum, StateMetrics> = {
  [ModelStateEnum.FLIGHT]: {
    length: "length",
    beam: "beam",
    height: "height",
    fleetchartLength: "fleetchartOffsetLength",
    fleetchartBeam: "fleetchartOffsetBeam",
  },
  [ModelStateEnum.EXTENDED]: {
    length: "extendedLength",
    beam: "extendedBeam",
    height: "extendedHeight",
    fleetchartLength: "extendedFleetchartOffsetLength",
    fleetchartBeam: "extendedFleetchartOffsetBeam",
  },
  [ModelStateEnum.LANDED]: {
    length: "landedLength",
    beam: "landedBeam",
    height: "landedHeight",
    fleetchartLength: "landedFleetchartOffsetLength",
    fleetchartBeam: "landedFleetchartOffsetBeam",
  },
};

function number(
  metrics: ModelMetrics,
  key: keyof ModelMetrics,
): number | undefined {
  const value = metrics[key];

  return typeof value === "number" ? value : undefined;
}

function file(media: ModelMedia, key: keyof ModelMedia): MediaFile | undefined {
  const value = media[key];

  return typeof value === "string" ? undefined : value;
}

function stateHolo(
  model: Model,
  state: ModelStateEnum,
  preferLite: boolean,
): MediaFile | undefined {
  const full = file(model.media, STATE_MEDIA[state].holo);
  const lite = file(model.media, STATE_MEDIA[state].holoLite);

  return preferLite ? lite || full : full || lite;
}

// The state's own holo, then the flying one -- and then whatever holo the model
// does have: a hull uploaded landed-first has no flying mesh to fall back to, and
// the alternative is a 3D view button that opens nothing.
//
// `lite` decides which of a state's two exports comes first, never whether the
// other one counts: the pose asked for matters more than the file size, so a
// desktop showing a state with only a lite export shows that export.
export function modelStateHolo(
  model: Model,
  state: ModelStateEnum,
  { lite = false }: { lite?: boolean } = {},
): MediaFile | undefined {
  return (
    stateHolo(model, state, lite) ||
    stateHolo(model, ModelStateEnum.FLIGHT, lite) ||
    MODEL_STATES.map((other) => stateHolo(model, other, lite)).find(Boolean)
  );
}

// The pair for one view, coloured and not, so the caller keeps its own rule about
// which it prefers at which screen size. A state that has neither falls back to
// the flight pair for that view alone: an extended set missing its front view
// should still show a front view.
export function modelStateView(
  model: Model,
  state: ModelStateEnum,
  view: ModelViewEnum,
): { regular?: MediaFile; colored?: MediaFile } {
  const keys = STATE_MEDIA[state].views[view];
  const regular = file(model.media, keys.regular);
  const colored = file(model.media, keys.colored);

  if (regular || colored) {
    return { regular, colored };
  }

  const fallback = STATE_MEDIA[ModelStateEnum.FLIGHT].views[view];

  return {
    regular: file(model.media, fallback.regular),
    colored: file(model.media, fallback.colored),
  };
}

function hasOwnViews(
  model: Model,
  state: ModelStateEnum,
  views: readonly ModelViewEnum[],
): boolean {
  const keys = STATE_MEDIA[state].views;

  return views.some(
    (view) =>
      file(model.media, keys[view].regular) ||
      file(model.media, keys[view].colored),
  );
}

// The views from behind borrow the flight set only as a whole row, and only
// where the views above them are the flight set too: a landed front row over a
// flying rear row draws one ship in two poses.
export function modelStateShowsRearViews(
  model: Model,
  state: ModelStateEnum,
): boolean {
  return (
    state === ModelStateEnum.FLIGHT ||
    hasOwnViews(model, state, MODEL_REAR_VIEWS) ||
    !hasOwnViews(model, state, MODEL_VIEWS)
  );
}

// Each figure falls back on its own: a landed holo measures all three, but a
// state entered by hand may carry only the one that differs.
export function modelStateMetrics(model: Model, state: ModelStateEnum) {
  const keys = STATE_METRICS[state];
  const metrics = model.metrics;

  const stateLength = number(metrics, keys.length);
  const stateBeam = number(metrics, keys.beam);

  return {
    length: stateLength || metrics.length,
    beam: stateBeam || metrics.beam,
    height: number(metrics, keys.height) || metrics.height,
    // What the views and the holo are drawn at, which is not the same question:
    // the state's own curated offset first, then what its holo measured, and only
    // then the flight offset. Falling through to the plain length before the
    // flight offset would draw a state with no figures of its own at a size
    // nobody curated.
    fleetchartLength:
      number(metrics, keys.fleetchartLength) ||
      stateLength ||
      metrics.fleetchartOffsetLength ||
      metrics.length,
    fleetchartBeam:
      number(metrics, keys.fleetchartBeam) ||
      stateBeam ||
      metrics.fleetchartOffsetBeam ||
      metrics.beam,
  };
}

function hasStateMedia(model: Model, state: ModelStateEnum): boolean {
  const { holo, holoLite, views } = STATE_MEDIA[state];

  return Boolean(
    file(model.media, holo) ||
    file(model.media, holoLite) ||
    ALL_MODEL_VIEWS.some(
      (view) =>
        file(model.media, views[view].regular) ||
        file(model.media, views[view].colored),
    ),
  );
}

// A measurement of its own, in any of the three dimensions: on several hulls the
// gear changes the height and nothing else, and that is still a state worth
// offering.
function hasStateMetrics(model: Model, state: ModelStateEnum): boolean {
  const keys = STATE_METRICS[state];

  return Boolean(
    number(model.metrics, keys.length) ||
    number(model.metrics, keys.beam) ||
    number(model.metrics, keys.height),
  );
}

// Flight is always on offer -- it is what every other state falls back to --
// and the other two only once the model carries something of their own.
export function modelHasState(model: Model, state: ModelStateEnum): boolean {
  return (
    state === ModelStateEnum.FLIGHT ||
    hasStateMetrics(model, state) ||
    hasStateMedia(model, state)
  );
}

export const useModelStates = (model: MaybeRefOrGetter<Model | undefined>) => {
  // What the views toggle offers: a state with any image or a measurement of its
  // own has something to show across the views and the dimension tiles.
  const availableStates = computed<ModelStateEnum[]>(() => {
    const value = toValue(model);

    if (!value) {
      return [ModelStateEnum.FLIGHT];
    }

    return MODEL_STATES.filter((state) => modelHasState(value, state));
  });

  // What the image toolbar offers, which is narrower: a state with images but no
  // holo of its own would give the viewer a button that changes nothing.
  const holoStates = computed<ModelStateEnum[]>(() => {
    const value = toValue(model);

    if (!value) {
      return [];
    }

    return MODEL_STATES.filter((state) =>
      Boolean(
        file(value.media, STATE_MEDIA[state].holo) ||
        file(value.media, STATE_MEDIA[state].holoLite),
      ),
    );
  });

  // A state persisted from a ship that had it, on a ship that does not.
  const resolveState = (state: ModelStateEnum): ModelStateEnum =>
    availableStates.value.includes(state) ? state : ModelStateEnum.FLIGHT;

  return { availableStates, holoStates, resolveState };
};
