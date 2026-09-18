import { computed, toValue, type MaybeRefOrGetter } from "vue";
import type {
  MediaFile,
  Model,
  ModelMedia,
  ModelMetrics,
} from "@/services/fyApi";

// The three states a ship is held in. `retracted` is the ship as it flies and is
// the only one every model has; the other two are uploaded per hull, and their
// dimensions are read off their own holo by MeasureHoloJob rather than typed.
export enum ModelStateEnum {
  RETRACTED = "retracted",
  EXTENDED = "extended",
  LANDED = "landed",
}

export enum ModelViewEnum {
  ANGLED = "angled",
  TOP = "top",
  FRONT = "front",
  SIDE = "side",
}

// The order the selector offers them in, and the order a fallback walks back to.
export const MODEL_STATES = [
  ModelStateEnum.RETRACTED,
  ModelStateEnum.EXTENDED,
  ModelStateEnum.LANDED,
] as const;

export const MODEL_VIEWS = [
  ModelViewEnum.ANGLED,
  ModelViewEnum.TOP,
  ModelViewEnum.FRONT,
  ModelViewEnum.SIDE,
] as const;

type ViewKeys = { regular: keyof ModelMedia; colored: keyof ModelMedia };

type StateMedia = {
  holo: keyof ModelMedia;
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
  [ModelStateEnum.RETRACTED]: {
    holo: "holo",
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
    },
  },
  [ModelStateEnum.EXTENDED]: {
    holo: "extendedHolo",
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
    },
  },
  [ModelStateEnum.LANDED]: {
    holo: "landedHolo",
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
    },
  },
};

const STATE_METRICS: Record<ModelStateEnum, StateMetrics> = {
  [ModelStateEnum.RETRACTED]: {
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

const number = (
  metrics: ModelMetrics,
  key: keyof ModelMetrics,
): number | undefined => {
  const value = metrics[key];

  return typeof value === "number" ? value : undefined;
};

const file = (
  media: ModelMedia,
  key: keyof ModelMedia,
): MediaFile | undefined => {
  const value = media[key];

  return typeof value === "string" ? undefined : value;
};

export const modelStateHolo = (
  model: Model,
  state: ModelStateEnum,
): MediaFile | undefined =>
  file(model.media, STATE_MEDIA[state].holo) || model.media.holo;

// The pair for one view, coloured and not, so the caller keeps its own rule about
// which it prefers at which screen size. A state that has neither falls back to
// the retracted pair for that view alone: an extended set missing its front view
// should still show a front view.
export const modelStateView = (
  model: Model,
  state: ModelStateEnum,
  view: ModelViewEnum,
): { regular?: MediaFile; colored?: MediaFile } => {
  const keys = STATE_MEDIA[state].views[view];
  const regular = file(model.media, keys.regular);
  const colored = file(model.media, keys.colored);

  if (regular || colored) {
    return { regular, colored };
  }

  const fallback = STATE_MEDIA[ModelStateEnum.RETRACTED].views[view];

  return {
    regular: file(model.media, fallback.regular),
    colored: file(model.media, fallback.colored),
  };
};

// Each figure falls back on its own: a landed holo measures all three, but a
// state entered by hand may carry only the one that differs.
export const modelStateMetrics = (model: Model, state: ModelStateEnum) => {
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
    // then the retracted offset. Falling through to the plain length before the
    // retracted offset would draw a state with no figures of its own at a size
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
};

const hasStateMedia = (model: Model, state: ModelStateEnum): boolean => {
  const { holo, views } = STATE_MEDIA[state];

  return Boolean(
    file(model.media, holo) ||
    MODEL_VIEWS.some(
      (view) =>
        file(model.media, views[view].regular) ||
        file(model.media, views[view].colored),
    ),
  );
};

// A measurement of its own, in any of the three dimensions: on several hulls the
// gear changes the height and nothing else, and that is still a state worth
// offering.
const hasStateMetrics = (model: Model, state: ModelStateEnum): boolean => {
  const keys = STATE_METRICS[state];

  return Boolean(
    number(model.metrics, keys.length) ||
    number(model.metrics, keys.beam) ||
    number(model.metrics, keys.height),
  );
};

// Retracted is always on offer -- it is what every other state falls back to --
// and the other two only once the model carries something of their own.
export const modelHasState = (model: Model, state: ModelStateEnum): boolean =>
  state === ModelStateEnum.RETRACTED ||
  hasStateMetrics(model, state) ||
  hasStateMedia(model, state);

export const useModelStates = (model: MaybeRefOrGetter<Model | undefined>) => {
  // What the views toggle offers: a state with any image or a measurement of its
  // own has something to show across the four views and the dimension tiles.
  const availableStates = computed<ModelStateEnum[]>(() => {
    const value = toValue(model);

    if (!value) {
      return [ModelStateEnum.RETRACTED];
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
      file(value.media, STATE_MEDIA[state].holo),
    );
  });

  // A state persisted from a ship that had it, on a ship that does not.
  const resolveState = (state: ModelStateEnum): ModelStateEnum =>
    availableStates.value.includes(state) ? state : ModelStateEnum.RETRACTED;

  return { availableStates, holoStates, resolveState };
};
