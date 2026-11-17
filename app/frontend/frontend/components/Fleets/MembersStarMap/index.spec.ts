import { mountWithDefaults } from "@/shared/utils/TestUtils";

const webglAvailable = vi.hoisted(() => vi.fn(() => true));

vi.mock("@/shared/utils/Webgl", () => ({ webglAvailable }));

vi.mock("@/services/fyApi", async (importOriginal) => {
  const { ref } = await import("vue");

  return {
    ...(await importOriginal<typeof import("@/services/fyApi")>()),
    useGalaxy: () => ({
      data: ref({
        systems: [
          {
            code: "STANTON",
            name: "Stanton",
            position: [49.5, -2.6, 16.5],
            systemType: "single_star",
            affiliations: ["UEE"],
            inGame: true,
          },
        ],
        tunnels: [],
      }),
    }),
  };
});

vi.mock("@tresjs/core", () => ({
  TresCanvas: { template: "<div data-test='canvas' />" },
  useLoop: () => ({ onBeforeRender: () => undefined }),
}));

vi.mock("@tresjs/cientos", () => ({
  OrbitControls: { template: "<div />" },
  Html: { template: "<div />" },
}));

const { default: MembersStarMap } = await import("./index.vue");

const mount = () =>
  mountWithDefaults<typeof MembersStarMap>(MembersStarMap, {
    props: { members: [] },
  });

describe("MembersStarMap", () => {
  beforeEach(() => {
    webglAvailable.mockReturnValue(true);
  });

  it("draws the map and its legend where WebGL works", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='canvas']").exists()).toBe(true);
    expect(wrapper.find(".starmap-legend").exists()).toBe(true);
    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(false);
  });

  it("says so where WebGL is missing, with nothing left to control", async () => {
    webglAvailable.mockReturnValue(false);

    const wrapper = await mount();

    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(true);
    expect(wrapper.find("[data-test='canvas']").exists()).toBe(false);
    expect(wrapper.find(".starmap-legend").exists()).toBe(false);
  });
});
