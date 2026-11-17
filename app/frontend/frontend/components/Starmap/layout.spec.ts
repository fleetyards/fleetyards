import {
  LocationKindEnum,
  NullableLocationBodyTypeEnum,
  type Location,
  type LocationJumpPoint,
  type LocationStarmapPlace,
} from "@/services/fyApi";
import { UNIT, chainOf, systemScene, systemsScene, toScene } from "./layout";

const place = (
  overrides: Partial<LocationStarmapPlace> & { id: string },
): LocationStarmapPlace => ({
  name: overrides.id,
  slug: overrides.id,
  kind: LocationKindEnum.STATION,
  parentName: null,
  parentId: null,
  position: [0, 0, 0],
  radius: null,
  shownOnStarmap: true,
  shownWithParentOnly: false,
  alwaysShown: false,
  quantumTravelDestination: true,
  lagrangePoint: false,
  gateway: false,
  color: null,
  unstable: false,
  bodyType: null,
  texture: null,
  ...overrides,
});

const HURSTON = 12_850_457_093;

const star = place({
  id: "stanton",
  kind: LocationKindEnum.STAR,
  radius: 696_000_000,
});
const hurston = place({
  id: "hurston",
  kind: LocationKindEnum.PLANET,
  parentId: "stanton",
  position: [HURSTON, 0, 0],
  radius: 1_000_000,
});
const crusader = place({
  id: "crusader",
  kind: LocationKindEnum.PLANET,
  parentId: "stanton",
  position: [0, -19_000_000_000, 0],
  radius: 7_450_000,
  bodyType: NullableLocationBodyTypeEnum.GAS_GIANT,
});
const aberdeen = place({
  id: "aberdeen",
  kind: LocationKindEnum.MOON,
  parentId: "hurston",
  position: [HURSTON + 40_000_000, 0, 0],
  radius: 274_000,
});
const lorville = place({
  id: "lorville",
  kind: LocationKindEnum.CITY,
  parentId: "hurston",
  position: [HURSTON + 1_000_000, 0, 0],
});
const klescher = place({
  id: "klescher",
  kind: LocationKindEnum.OUTPOST,
  parentId: "aberdeen",
  position: [HURSTON + 40_274_000, 0, 0],
});
const hurL1 = place({
  id: "hur-l1",
  parentId: "hurston",
  lagrangePoint: true,
  position: [11_565_411_383, 0, 0],
});
const hurL1Station = place({
  id: "hur-l1-station",
  parentId: "hur-l1",
  position: [11_565_411_383, 5_000, 0],
});
const everus = place({
  id: "everus-harbor",
  parentId: "hurston",
  position: [HURSTON + 1_030_000, 0, 0],
});
const clinic = place({
  id: "everus-harbor-clinic",
  kind: LocationKindEnum.CLINIC,
  parentId: "everus-harbor",
  position: [HURSTON + 1_032_000, 0, 0],
});

const places = [
  star,
  hurston,
  crusader,
  aberdeen,
  lorville,
  klescher,
  hurL1,
  hurL1Station,
  everus,
  clinic,
];

const scene = systemScene(places);
const find = (key: string) => scene.items.find((item) => item.key === key)!;

describe("toScene", () => {
  it("turns the game's z-up space into three.js's y-up space", () => {
    expect(toScene([1, 2, 3], [0, 0, 0], 1)).toEqual([1, 3, -2]);
  });
});

describe("systemScene", () => {
  it("puts the whole system in one world, a megametre to the unit, the star at the centre", () => {
    expect(find("stanton").position).toEqual([0, 0, 0]);
    expect(find("hurston").position[0]).toBeCloseTo(HURSTON / UNIT);
    expect(find("lorville").position[0]).toBeCloseTo(
      (HURSTON + 1_000_000) / UNIT,
    );
  });

  it("anchors every place to the body it belongs to", () => {
    expect(find("hurston").anchor).toBe("stanton");
    expect(find("aberdeen").anchor).toBe("hurston");
    expect(find("lorville").anchor).toBe("hurston");
    expect(find("klescher").anchor).toBe("aberdeen");
    expect(find("stanton").anchor).toBeNull();
  });

  it("draws a Lagrange point and what is at it with the star, named by the station", () => {
    expect(find("hur-l1").anchor).toBe("stanton");
    expect(find("hur-l1-station").anchor).toBe("stanton");
    expect(find("hur-l1").labelled).toBe(false);
    expect(find("hur-l1-station").labelled).toBe(true);
  });

  it("folds a place inside another one into it, so a click lands on the station", () => {
    const keys = scene.items.map((item) => item.key);

    expect(keys).toContain("everus-harbor");
    expect(keys).not.toContain("everus-harbor-clinic");
  });

  it("gives the planets orbits around the star and the moons around their planet", () => {
    const orbit = (body: string) =>
      scene.orbits.find((entry) => entry.body === body);

    expect(orbit("hurston")?.center).toBe("stanton");
    expect(orbit("hurston")?.radius).toBeCloseTo(HURSTON / UNIT);
    expect(orbit("aberdeen")?.center).toBe("hurston");
    expect(orbit("aberdeen")?.radius).toBeCloseTo(40);
  });

  it("paints a body by its type, as the location pages do", () => {
    expect(find("hurston").surface).toBe("rocky");
    expect(find("crusader").surface).toBe("gas");
    expect(find("aberdeen").surface).toBe("cratered");
    expect(find("lorville").surface).toBeNull();
  });

  it("frames the overview on the outermost planet", () => {
    expect(scene.extent).toBeCloseTo(19_000);
  });
});

describe("chainOf", () => {
  it("walks from the star out to a place", () => {
    expect(chainOf(scene, "klescher").map((item) => item.key)).toEqual([
      "stanton",
      "hurston",
      "aberdeen",
      "klescher",
    ]);
  });

  it("is empty without a focus", () => {
    expect(chainOf(scene, null)).toEqual([]);
  });
});

describe("systemsScene", () => {
  const system = (id: string) =>
    ({
      id,
      name: `${id} System`,
      slug: `${id}-system`,
      kind: LocationKindEnum.SYSTEM,
    }) as Location;

  const jump = (
    from: string,
    to: string | null,
    temporary = false,
  ): LocationJumpPoint => ({
    location: {
      id: `${from}-${to}`,
      name: null,
      slug: `${from}-${to}`,
      kind: LocationKindEnum.JUMP_POINT,
      parentName: null,
    },
    systemId: from,
    destinationName: to ?? "Unknown",
    destinationSystemId: to,
    temporary,
  });

  it("joins the systems once per tunnel, whichever end lists it", () => {
    const ring = systemsScene(
      [system("stanton"), system("pyro"), system("nyx")],
      [
        jump("stanton", "pyro"),
        jump("pyro", "stanton"),
        jump("stanton", "nyx", true),
        jump("nyx", null),
      ],
    );

    expect(ring.items).toHaveLength(3);
    expect(ring.links).toHaveLength(2);
    expect(ring.links.filter((link) => link.temporary)).toHaveLength(1);
  });

  it("draws a tunnel as temporary only while every tunnel of the pair is", () => {
    const ring = systemsScene(
      [system("stanton"), system("nyx")],
      [jump("stanton", "nyx", true), jump("nyx", "stanton")],
    );

    expect(ring.links).toEqual([expect.objectContaining({ temporary: false })]);
  });
});
