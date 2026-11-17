import {
  LocationKindEnum,
  type Location,
  type LocationJumpPoint,
  type LocationStarmapPlace,
} from "@/services/fyApi";
import {
  BODY_UNIT,
  SYSTEM_UNIT,
  bodyScene,
  systemScene,
  systemsScene,
  toScene,
} from "./layout";

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
  ...overrides,
});

const star = place({
  id: "stanton",
  kind: LocationKindEnum.STAR,
  radius: 696_000_000,
});
const hurston = place({
  id: "hurston",
  kind: LocationKindEnum.PLANET,
  parentId: "stanton",
  position: [12_850_457_093, 0, 0],
  radius: 1_000_000,
});
const aberdeen = place({
  id: "aberdeen",
  kind: LocationKindEnum.MOON,
  parentId: "hurston",
  position: [12_850_457_093 + 40_000_000, 0, 0],
  radius: 274_000,
});
const lorville = place({
  id: "lorville",
  kind: LocationKindEnum.CITY,
  parentId: "hurston",
  position: [12_850_457_093 + 1_000_000, 0, 0],
});
const klescher = place({
  id: "klescher",
  kind: LocationKindEnum.OUTPOST,
  parentId: "aberdeen",
  position: [12_850_457_093 + 40_274_000, 0, 0],
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
  position: [11_565_411_383, 10, 0],
});
const gateway = place({
  id: "pyro-gateway",
  parentId: "stanton",
  gateway: true,
  position: [0, 20_000_000_000, 0],
});

const places = [
  star,
  hurston,
  aberdeen,
  lorville,
  klescher,
  hurL1,
  hurL1Station,
  gateway,
];

const keys = (items: { key: string }[]) => items.map((item) => item.key).sort();

describe("toScene", () => {
  it("turns the game's z-up space into three.js's y-up space", () => {
    expect(toScene([1, 2, 3], [0, 0, 0], 1)).toEqual([1, 3, -2]);
  });
});

describe("systemScene", () => {
  const scene = systemScene(places);

  it("draws the star, its planets, the gateways, and the Lagrange points with what sits at them", () => {
    expect(keys(scene.items)).toEqual(
      ["stanton", "hurston", "hur-l1", "hur-l1-station", "pyro-gateway"].sort(),
    );
  });

  it("puts the planets at gigametre scale on their orbits", () => {
    const planet = scene.items.find((item) => item.key === "hurston");

    expect(planet?.position[0]).toBeCloseTo(12_850_457_093 / SYSTEM_UNIT);
    expect(scene.orbits).toHaveLength(1);
    expect(scene.orbits[0]).toBeCloseTo(12_850_457_093 / SYSTEM_UNIT);
  });

  it("lets a planet be opened, and nothing smaller", () => {
    const enterable = scene.items.filter((item) => item.enterable);

    expect(keys(enterable)).toEqual(["hurston"]);
  });
});

describe("bodyScene", () => {
  it("centres the body and keeps what belongs to it rather than to its moons", () => {
    const scene = bodyScene(places, "hurston");

    expect(keys(scene!.items)).toEqual(
      ["hurston", "aberdeen", "lorville"].sort(),
    );
    expect(
      scene!.items.find((item) => item.key === "hurston")?.position,
    ).toEqual([0, 0, 0]);
    expect(scene!.orbits[0]).toBeCloseTo(40_000_000 / BODY_UNIT);
  });

  it("leaves a Lagrange point and what sits at it to the system", () => {
    const scene = bodyScene(places, "hurston");

    expect(keys(scene!.items)).not.toContain("hur-l1-station");
  });

  it("shows a moon with what is on it", () => {
    const scene = bodyScene(places, "aberdeen");

    expect(keys(scene!.items)).toEqual(["aberdeen", "klescher"]);
  });

  it("folds a place inside another one into it, so a click lands on the station", () => {
    const everus = place({
      id: "everus-harbor",
      parentId: "hurston",
      position: [12_850_457_093 + 1_030_000, 0, 0],
    });
    const clinic = place({
      id: "everus-harbor-clinic",
      kind: LocationKindEnum.CLINIC,
      parentId: "everus-harbor",
      position: [12_850_457_093 + 1_032_000, 0, 0],
    });

    const scene = bodyScene([...places, everus, clinic], "hurston");

    expect(keys(scene!.items)).toContain("everus-harbor");
    expect(keys(scene!.items)).not.toContain("everus-harbor-clinic");
  });

  it("has nothing for a place that is not a body", () => {
    expect(bodyScene(places, "lorville")).toBeNull();
    expect(bodyScene(places, "nowhere")).toBeNull();
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
    const scene = systemsScene(
      [system("stanton"), system("pyro"), system("nyx")],
      [
        jump("stanton", "pyro"),
        jump("pyro", "stanton"),
        jump("stanton", "nyx", true),
        jump("nyx", null),
      ],
    );

    expect(scene.items).toHaveLength(3);
    expect(scene.links).toHaveLength(2);
    expect(scene.links.filter((link) => link.temporary)).toHaveLength(1);
  });

  it("draws a tunnel as temporary only while every tunnel of the pair is", () => {
    const scene = systemsScene(
      [system("stanton"), system("nyx")],
      [jump("stanton", "nyx", true), jump("nyx", "stanton")],
    );

    expect(scene.links).toEqual([
      expect.objectContaining({ temporary: false }),
    ]);
  });
});
