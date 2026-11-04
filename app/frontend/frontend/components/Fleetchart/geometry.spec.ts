import { describe, expect, it } from "vitest";
import type { MediaFile } from "@/services/fyApi";
import {
  FleetchartShipStates,
  FleetchartViewpoints,
} from "@/shared/stores/fleetchart";
import {
  hasStateViews,
  imageUrlFor,
  shipGeometry,
  viewFor,
  type FleetchartEntry,
} from "./geometry";

const view = (name: string, width = 1000, height = 500) => ({
  url: `${name}.png`,
  largeUrl: `${name}-large.png`,
  mediumUrl: `${name}-medium.png`,
  width,
  height,
});

const model = (media: object, metrics: object = {}) =>
  ({
    slug: "ship",
    media,
    metrics: { fleetchartOffsetLength: 100, ...metrics },
  }) as unknown as FleetchartEntry;

describe("shipGeometry", () => {
  it("sizes a ship from its length and largest view", () => {
    expect(
      shipGeometry(
        model({ portView: view("port"), topView: view("top", 1000, 800) }),
        FleetchartViewpoints.PORT,
      ),
    ).toEqual({ length: 100, height: 80, imageWidth: 100, imageHeight: 50 });
  });

  it("uses the beam when it exceeds the length", () => {
    expect(
      shipGeometry(
        model(
          { topView: view("top", 1000, 1000) },
          { fleetchartOffsetBeam: 150 },
        ),
        FleetchartViewpoints.TOP,
      )?.height,
    ).toBe(150);
  });

  it("draws a front or rear view as wide as the beam, not the length", () => {
    const entry = model(
      {
        portView: view("port", 1000, 400),
        rearView: view("rear", 800, 400),
        frontView: view("front", 800, 400),
      },
      { fleetchartOffsetBeam: 30 },
    );

    expect(shipGeometry(entry, FleetchartViewpoints.REAR)?.imageWidth).toBe(30);
    expect(shipGeometry(entry, FleetchartViewpoints.FRONT)?.imageHeight).toBe(
      15,
    );
    expect(shipGeometry(entry, FleetchartViewpoints.PORT)?.imageWidth).toBe(
      100,
    );
  });

  it("uses the landed length and views in the landed state", () => {
    const entry = model(
      { portView: view("port"), landedPortView: view("landed") },
      { landedLength: 120 },
    );
    const options = { state: FleetchartShipStates.LANDED };

    expect(
      shipGeometry(entry, FleetchartViewpoints.PORT, options)?.length,
    ).toBe(120);
    expect(viewFor(entry, FleetchartViewpoints.PORT, options)?.url).toBe(
      "landed.png",
    );
  });

  it("keeps a ship's flight size when it has no picture of the state", () => {
    const entry = model({ portView: view("port") }, { landedLength: 500 });

    expect(
      shipGeometry(entry, FleetchartViewpoints.PORT, {
        state: FleetchartShipStates.LANDED,
      })?.length,
    ).toBe(100);
  });

  it("does not count a holo as a picture of a state", () => {
    const entry = model({
      portView: view("port"),
      landedHolo: { url: "landed.glb" },
    });

    expect(hasStateViews(entry, FleetchartShipStates.LANDED)).toBe(false);
  });

  it("falls back to the flight view for a state a ship has no picture of", () => {
    const entry = model({ portView: view("port") });

    expect(
      viewFor(entry, FleetchartViewpoints.PORT, {
        state: FleetchartShipStates.LANDED,
      })?.url,
    ).toBe("port.png");
    expect(hasStateViews(entry, FleetchartShipStates.LANDED)).toBe(false);
    expect(hasStateViews(entry, FleetchartShipStates.FLIGHT)).toBe(true);
  });

  it("keeps the box when the viewpoint changes", () => {
    const entry = model({
      portView: view("port", 1000, 200),
      topView: view("top", 1000, 500),
    });

    expect(shipGeometry(entry, FleetchartViewpoints.PORT)?.height).toBe(
      shipGeometry(entry, FleetchartViewpoints.TOP)?.height,
    );
  });

  it("uses the extended length only in the extended state", () => {
    const entry = model(
      { portView: view("port"), extendedPortView: view("extended") },
      { extendedFleetchartOffsetLength: 200 },
    );

    expect(shipGeometry(entry, FleetchartViewpoints.PORT)?.length).toBe(100);
    expect(
      shipGeometry(entry, FleetchartViewpoints.PORT, {
        state: FleetchartShipStates.EXTENDED,
      })?.length,
    ).toBe(200);
  });

  it("has nothing to draw before the views arrive", () => {
    expect(shipGeometry(model({}), FleetchartViewpoints.PORT)).toBeUndefined();
  });

  it("draws no image for a viewpoint the ship lacks, but keeps its box", () => {
    expect(
      shipGeometry(model({ portView: view("port") }), FleetchartViewpoints.TOP),
    ).toEqual({ length: 100, height: 50, imageWidth: 0, imageHeight: 0 });
  });
});

describe("viewFor", () => {
  const media = {
    portView: view("port"),
    portViewColored: view("port-colored"),
    extendedPortView: view("extended"),
    extendedPortViewColored: view("extended-colored"),
  };

  it("prefers the most specific view it was asked for", () => {
    const entry = model(media);

    expect(viewFor(entry, FleetchartViewpoints.PORT)?.url).toBe("port.png");
    expect(
      viewFor(entry, FleetchartViewpoints.PORT, { colored: true })?.url,
    ).toBe("port-colored.png");
    expect(
      viewFor(entry, FleetchartViewpoints.PORT, {
        state: FleetchartShipStates.EXTENDED,
      })?.url,
    ).toBe("extended.png");
    expect(
      viewFor(entry, FleetchartViewpoints.PORT, {
        state: FleetchartShipStates.EXTENDED,
        colored: true,
      })?.url,
    ).toBe("extended-colored.png");
  });

  it("finds the rear views, colored and extended too", () => {
    const entry = model({
      rearView: view("rear"),
      rearViewColored: view("rear-colored"),
      extendedStarboardView: view("starboard-extended"),
      starboardView: view("starboard"),
      bottomView: view("bottom"),
      angledRearView: view("angled-rear"),
    });

    expect(
      viewFor(entry, FleetchartViewpoints.REAR, { colored: true })?.url,
    ).toBe("rear-colored.png");
    expect(
      viewFor(entry, FleetchartViewpoints.STARBOARD, {
        state: FleetchartShipStates.EXTENDED,
      })?.url,
    ).toBe("starboard-extended.png");
    expect(viewFor(entry, FleetchartViewpoints.BOTTOM)?.url).toBe("bottom.png");
    expect(viewFor(entry, FleetchartViewpoints.ANGLED_REAR)?.url).toBe(
      "angled-rear.png",
    );
  });

  it("skips a colored view without a file", () => {
    expect(
      viewFor(
        model({ portView: view("port"), portViewColored: { url: null } }),
        FleetchartViewpoints.PORT,
        { colored: true },
      )?.url,
    ).toBe("port.png");
  });

  it("lets a vehicle's module package replace the model's view", () => {
    const vehicle = {
      model: model({ portView: view("port") }),
      modulePackage: { media: { portView: view("module") } },
    } as unknown as FleetchartEntry;

    expect(viewFor(vehicle, FleetchartViewpoints.PORT)?.url).toBe("module.png");
  });

  it("keeps the model's front view, as module packages have none", () => {
    const vehicle = {
      model: model({ frontView: view("front") }),
      modulePackage: { media: { frontView: view("module") } },
    } as unknown as FleetchartEntry;

    expect(viewFor(vehicle, FleetchartViewpoints.FRONT)?.url).toBe("front.png");
  });
});

describe("imageUrlFor", () => {
  it("picks the smallest image that covers the rendered width", () => {
    const file = view("port") as MediaFile;

    expect(imageUrlFor(file, 400)).toBe("port-medium.png");
    expect(imageUrlFor(file, 1000)).toBe("port-large.png");
    expect(imageUrlFor(file, 2000)).toBe("port.png");
  });
});
