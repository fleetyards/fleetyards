import { describe, expect, it } from "vitest";
import type { MediaFile } from "@/services/fyApi";
import { FleetchartViewpoints } from "@/shared/stores/fleetchart";
import {
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
    ).toEqual({ length: 100, height: 80, imageWidth: 100 });
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
      { portView: view("port") },
      { extendedFleetchartOffsetLength: 200 },
    );

    expect(shipGeometry(entry, FleetchartViewpoints.PORT)?.length).toBe(100);
    expect(
      shipGeometry(entry, FleetchartViewpoints.PORT, { extended: true })
        ?.length,
    ).toBe(200);
  });

  it("has nothing to draw before the views arrive", () => {
    expect(shipGeometry(model({}), FleetchartViewpoints.PORT)).toBeUndefined();
  });

  it("draws no image for a viewpoint the ship lacks, but keeps its box", () => {
    expect(
      shipGeometry(model({ portView: view("port") }), FleetchartViewpoints.TOP),
    ).toEqual({ length: 100, height: 50, imageWidth: 0 });
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
      viewFor(entry, FleetchartViewpoints.PORT, { extended: true })?.url,
    ).toBe("extended.png");
    expect(
      viewFor(entry, FleetchartViewpoints.PORT, {
        extended: true,
        colored: true,
      })?.url,
    ).toBe("extended-colored.png");
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
