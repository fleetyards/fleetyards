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
    ).toEqual({
      length: 100,
      height: 80,
      imageWidth: 100,
      imageHeight: 50,
      frameWidth: 100,
    });
  });

  it("makes room for a beam that exceeds the length", () => {
    expect(
      shipGeometry(
        model(
          { topView: view("top", 1000, 1500) },
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

  it("makes room for a front view wider and taller than the flight box", () => {
    const geometry = shipGeometry(
      model(
        {
          portView: view("port", 1000, 100),
          frontView: view("front", 100, 100),
        },
        { fleetchartOffsetBeam: 150 },
      ),
      FleetchartViewpoints.FRONT,
    );

    expect(geometry?.frameWidth).toBe(150);
    expect(geometry?.height).toBe(150);
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

  describe("at the same scale in every state", () => {
    const picture = (width: number, height: number) => ({
      url: "view.png",
      width,
      height,
    });

    // A ship whose side view is taller than it is long in flight, as the Railen's is.
    const railen = {
      metrics: {
        fleetchartOffsetLength: 49.9,
        fleetchartOffsetBeam: 51.38,
        landedLength: 60.47,
        landedBeam: 51.38,
      },
      media: {
        portView: picture(2853, 3840),
        topView: picture(3730, 3840),
        landedPortView: picture(3840, 2327),
        landedTopView: picture(3840, 3263),
      },
    } as unknown as FleetchartEntry;

    it("draws a side view as long as the ship, however tall the picture is", () => {
      const flight = shipGeometry(railen, FleetchartViewpoints.PORT);

      expect(flight?.imageWidth).toBeCloseTo(49.9);
      expect(flight?.imageHeight).toBeCloseTo(67.16, 1);
    });

    it("gives a state its own length and its picture's shape", () => {
      const landed = shipGeometry(railen, FleetchartViewpoints.PORT, {
        state: FleetchartShipStates.LANDED,
      });

      expect(landed?.imageWidth).toBeCloseTo(60.47);
      expect(landed?.imageHeight).toBeCloseTo(36.64, 1);
    });

    it("matches the beam from above, in flight and landed", () => {
      expect(
        shipGeometry(railen, FleetchartViewpoints.TOP)?.imageHeight,
      ).toBeCloseTo(51.38, 0);
      expect(
        shipGeometry(railen, FleetchartViewpoints.TOP, {
          state: FleetchartShipStates.LANDED,
        })?.imageHeight,
      ).toBeCloseTo(51.38, 0);
    });

    it("keeps the box tall enough for the tallest picture between viewpoints", () => {
      expect(
        shipGeometry(railen, FleetchartViewpoints.TOP)?.height,
      ).toBeCloseTo(67.16, 1);
    });

    it("widens an angled view by the beam, so spread and folded wings match", () => {
      const clipper = {
        metrics: {
          fleetchartOffsetLength: 26.99,
          fleetchartOffsetBeam: 49.48,
          landedLength: 26.99,
          landedBeam: 21.14,
        },
        media: {
          angledView: picture(3840, 2162),
          angledRearView: picture(3840, 2162),
          landedAngledView: picture(3825, 3840),
        },
      } as unknown as FleetchartEntry;

      expect(
        shipGeometry(clipper, FleetchartViewpoints.ANGLED)?.imageWidth,
      ).toBeCloseTo(39.85, 1);
      expect(
        shipGeometry(clipper, FleetchartViewpoints.ANGLED, {
          state: FleetchartShipStates.LANDED,
        })?.imageWidth,
      ).toBeCloseTo(24.24, 1);
      expect(
        shipGeometry(clipper, FleetchartViewpoints.ANGLED_REAR)?.imageWidth,
      ).toBeCloseTo(42.2, 1);
    });

    it("uses an angled picture's measured width, in its own state", () => {
      const measured = {
        metrics: {
          fleetchartOffsetLength: 26.99,
          fleetchartOffsetBeam: 49.48,
          landedLength: 30,
          landedBeam: 21.14,
        },
        media: {
          angledView: picture(3840, 2162),
          landedAngledView: picture(3825, 3840),
          angledRearView: picture(3840, 2162),
          portView: picture(3840, 1853),
          angledExtents: {
            flight: { angled: 1.5, angledRear: 1.6 },
            landed: { angled: 0.8, angledRear: 0.9 },
          },
        },
      } as unknown as FleetchartEntry;

      expect(
        shipGeometry(measured, FleetchartViewpoints.ANGLED)?.imageWidth,
      ).toBeCloseTo(40.49, 1);
      expect(
        shipGeometry(measured, FleetchartViewpoints.ANGLED_REAR)?.imageWidth,
      ).toBeCloseTo(43.18, 1);
      expect(
        shipGeometry(measured, FleetchartViewpoints.ANGLED, {
          state: FleetchartShipStates.LANDED,
        })?.imageWidth,
      ).toBeCloseTo(24, 1);
      // Landed has no rear picture of its own, so it borrows flight's picture and size.
      expect(
        shipGeometry(measured, FleetchartViewpoints.ANGLED_REAR, {
          state: FleetchartShipStates.LANDED,
        })?.imageWidth,
      ).toBeCloseTo(43.18, 1);
    });

    it("draws a module package's angled picture at the package's own width", () => {
      const endeavor = model(
        {
          angledView: view("angled", 3840, 2280),
          angledExtents: { flight: { angled: 0.7425, angledRear: 0.8 } },
        },
        { fleetchartOffsetLength: 200, fleetchartOffsetBeam: 47.32 },
      );
      const vehicle = (media: object) =>
        ({ model: endeavor, modulePackage: { media } }) as FleetchartEntry;

      expect(
        shipGeometry(
          vehicle({
            angledView: view("master", 3719, 2154),
            angledExtent: 1.054,
          }),
          FleetchartViewpoints.ANGLED,
        )?.imageWidth,
      ).toBeCloseTo(210.8, 1);
      // Unmeasured, it is not drawn at the width of the ship's outline alone.
      expect(
        shipGeometry(
          vehicle({ angledView: view("master", 3719, 2154) }),
          FleetchartViewpoints.ANGLED,
        )?.imageWidth,
      ).toBeCloseTo(145.3, 1);
      expect(
        shipGeometry(
          vehicle({ portView: view("port", 3528, 796) }),
          FleetchartViewpoints.ANGLED,
        )?.imageWidth,
      ).toBeCloseTo(148.5, 1);
    });

    it("keeps a borrowed flight picture at its flight size", () => {
      const scorpius = {
        metrics: {
          fleetchartOffsetLength: 23.01,
          fleetchartOffsetBeam: 32.83,
          landedLength: 29.96,
          landedBeam: 13.3,
        },
        media: {
          frontView: picture(3840, 1000),
          portView: picture(3840, 2187),
          landedPortView: picture(3840, 766),
        },
      } as unknown as FleetchartEntry;

      expect(
        shipGeometry(scorpius, FleetchartViewpoints.FRONT, {
          state: FleetchartShipStates.LANDED,
        })?.imageWidth,
      ).toBeCloseTo(32.83);
    });
  });

  it("has nothing to draw before the views arrive", () => {
    expect(shipGeometry(model({}), FleetchartViewpoints.PORT)).toBeUndefined();
  });

  it("draws no image for a viewpoint the ship lacks, but keeps its box", () => {
    expect(
      shipGeometry(model({ portView: view("port") }), FleetchartViewpoints.TOP),
    ).toEqual({
      length: 100,
      height: 50,
      imageWidth: 0,
      imageHeight: 0,
      frameWidth: 100,
    });
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
