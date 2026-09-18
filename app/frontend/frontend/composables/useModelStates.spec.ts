import { describe, it, expect } from "vitest";
import type {
  MediaFile,
  Model,
  ModelMedia,
  ModelMetrics,
} from "@/services/fyApi";
import {
  ModelStateEnum,
  ModelViewEnum,
  modelHasState,
  modelStateHolo,
  modelStateMetrics,
  modelStateView,
  useModelStates,
} from "./useModelStates";

function file(name: string): MediaFile {
  return {
    name,
    url: `https://cdn.test/${name}`,
    largeUrl: `https://cdn.test/${name}?large`,
  } as MediaFile;
}

function model(
  media: Partial<ModelMedia> = {},
  metrics: Partial<ModelMetrics> = {},
): Model {
  return {
    media: { ...media },
    metrics: {
      length: 30,
      beam: 20,
      height: 10,
      fleetchartOffsetLength: 32,
      ...metrics,
    },
  } as Model;
}

describe("the states a model offers", () => {
  it("offers flight alone when nothing else is uploaded", () => {
    const { availableStates } = useModelStates(model());

    expect(availableStates.value).toEqual([ModelStateEnum.FLIGHT]);
  });

  it("offers a state that has only a measurement", () => {
    const { availableStates } = useModelStates(model({}, { landedHeight: 12 }));

    expect(availableStates.value).toEqual([
      ModelStateEnum.FLIGHT,
      ModelStateEnum.LANDED,
    ]);
  });

  it("offers a state that has only images", () => {
    const { availableStates } = useModelStates(
      model({ extendedSideView: file("ext-side") }),
    );

    expect(availableStates.value).toEqual([
      ModelStateEnum.FLIGHT,
      ModelStateEnum.EXTENDED,
    ]);
  });

  it("keeps them in flight, extended, landed order", () => {
    const { availableStates } = useModelStates(
      model({ landedHolo: file("landed"), extendedHolo: file("extended") }),
    );

    expect(availableStates.value).toEqual([
      ModelStateEnum.FLIGHT,
      ModelStateEnum.EXTENDED,
      ModelStateEnum.LANDED,
    ]);
  });

  it("follows a ref, so a page that swaps its model re-reads them", () => {
    const current = ref(model());
    const { availableStates } = useModelStates(current);

    expect(availableStates.value).toEqual([ModelStateEnum.FLIGHT]);

    current.value = model({ landedHolo: file("landed") });

    expect(availableStates.value).toEqual([
      ModelStateEnum.FLIGHT,
      ModelStateEnum.LANDED,
    ]);
  });

  it("counts landed images but not a landed state on a bare model", () => {
    expect(modelHasState(model(), ModelStateEnum.FLIGHT)).toBe(true);
    expect(modelHasState(model(), ModelStateEnum.LANDED)).toBe(false);
    expect(
      modelHasState(
        model({ landedTopViewColored: file("lt") }),
        ModelStateEnum.LANDED,
      ),
    ).toBe(true);
  });
});

describe("the states the image toolbar offers", () => {
  it("lists only the states with a holo of their own", () => {
    const { holoStates } = useModelStates(
      model({
        holo: file("holo"),
        landedHolo: file("landed"),
        extendedTopView: file("ext-top"),
      }),
    );

    expect(holoStates.value).toEqual([
      ModelStateEnum.FLIGHT,
      ModelStateEnum.LANDED,
    ]);
  });

  it("is empty for a model with no holo at all", () => {
    const { holoStates } = useModelStates(model({ landedTopView: file("lt") }));

    expect(holoStates.value).toEqual([]);
  });
});

describe("resolving a persisted state", () => {
  it("keeps a state the model has", () => {
    const { resolveState } = useModelStates(
      model({ landedHolo: file("landed") }),
    );

    expect(resolveState(ModelStateEnum.LANDED)).toBe(ModelStateEnum.LANDED);
  });

  it("falls back to flight on a model that does not have it", () => {
    const { resolveState } = useModelStates(model());

    expect(resolveState(ModelStateEnum.LANDED)).toBe(ModelStateEnum.FLIGHT);
  });
});

describe("picking the holo", () => {
  it("takes the state's own holo", () => {
    const subject = model({ holo: file("holo"), landedHolo: file("landed") });

    expect(modelStateHolo(subject, ModelStateEnum.LANDED)?.name).toBe("landed");
  });

  it("falls back to the flying holo, so a state with images alone still renders one", () => {
    const subject = model({ holo: file("holo"), landedTopView: file("lt") });

    expect(modelStateHolo(subject, ModelStateEnum.LANDED)?.name).toBe("holo");
  });

  // Uploaded landed-first, with no flying mesh behind it: the 3D view has to open
  // the holo the model does have rather than nothing at all.
  it("takes the only holo there is when the flying one is missing", () => {
    const subject = model({ landedHolo: file("landed") });

    expect(modelStateHolo(subject, ModelStateEnum.FLIGHT)?.name).toBe("landed");
  });
});

describe("picking a view", () => {
  it("takes the state's pair, coloured and not", () => {
    const subject = model({
      sideView: file("side"),
      landedSideView: file("landed-side"),
      landedSideViewColored: file("landed-side-colored"),
    });

    expect(
      modelStateView(subject, ModelStateEnum.LANDED, ModelViewEnum.SIDE),
    ).toEqual({
      regular: expect.objectContaining({ name: "landed-side" }),
      colored: expect.objectContaining({ name: "landed-side-colored" }),
    });
  });

  // The extended set the site has today is partial on several hulls: the toggle
  // must not blank a view the state happens not to carry.
  it("falls back to the flight pair for a view the state is missing", () => {
    const subject = model({
      frontView: file("front"),
      frontViewColored: file("front-colored"),
      landedSideView: file("landed-side"),
    });

    expect(
      modelStateView(subject, ModelStateEnum.LANDED, ModelViewEnum.FRONT),
    ).toEqual({
      regular: expect.objectContaining({ name: "front" }),
      colored: expect.objectContaining({ name: "front-colored" }),
    });
  });

  it("does not fall back when the state has the coloured one only", () => {
    const subject = model({
      topView: file("top"),
      landedTopViewColored: file("landed-top-colored"),
    });

    expect(
      modelStateView(subject, ModelStateEnum.LANDED, ModelViewEnum.TOP),
    ).toEqual({
      regular: undefined,
      colored: expect.objectContaining({ name: "landed-top-colored" }),
    });
  });
});

describe("picking the metrics", () => {
  it("reads the flight figures as they are", () => {
    expect(modelStateMetrics(model(), ModelStateEnum.FLIGHT)).toEqual({
      length: 30,
      beam: 20,
      height: 10,
      fleetchartLength: 32,
      fleetchartBeam: 20,
    });
  });

  // The Sabre Raven EX: the gear changes the height and nothing else.
  it("swaps only the figures the state measured", () => {
    const subject = model({}, { landedHeight: 12.5 });

    expect(modelStateMetrics(subject, ModelStateEnum.LANDED)).toMatchObject({
      length: 30,
      beam: 20,
      height: 12.5,
    });
  });

  it("draws at the state's own fleetchart offset where it has one", () => {
    const subject = model(
      {},
      { landedLength: 34, landedFleetchartOffsetLength: 36 },
    );

    expect(
      modelStateMetrics(subject, ModelStateEnum.LANDED).fleetchartLength,
    ).toBe(36);
  });

  it("falls back to the state's measurement, then to the flight offset", () => {
    expect(
      modelStateMetrics(model({}, { landedLength: 34 }), ModelStateEnum.LANDED)
        .fleetchartLength,
    ).toBe(34);
    expect(
      modelStateMetrics(model(), ModelStateEnum.LANDED).fleetchartLength,
    ).toBe(32);
  });
});
