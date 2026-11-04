import { mountWithDefaults } from "@/shared/utils/TestUtils";

const webglAvailable = vi.hoisted(() => vi.fn(() => true));

vi.mock("@/shared/utils/Webgl", () => ({ webglAvailable }));

vi.mock("@tresjs/core", () => ({
  TresCanvas: { template: "<div data-test='canvas' />" },
  useLoop: () => ({ onBeforeRender: () => undefined }),
  useTresContext: () => ({}),
}));

vi.mock("@tresjs/cientos", () => ({
  OrbitControls: { template: "<div />" },
  Grid: { template: "<div />" },
  Html: { template: "<div />" },
}));

const { default: CargoGridViewer } = await import("./index.vue");

const mount = () =>
  mountWithDefaults<typeof CargoGridViewer>(CargoGridViewer, {
    props: { cargoHolds: [] },
  });

describe("CargoGridViewer", () => {
  beforeEach(() => {
    webglAvailable.mockReturnValue(true);
  });

  it("draws the grid and its camera reset where WebGL works", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='canvas']").exists()).toBe(true);
    expect(wrapper.find(".cargo-grid-viewer__reset").exists()).toBe(true);
    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(false);
  });

  it("says so where WebGL is missing, with nothing left to control", async () => {
    webglAvailable.mockReturnValue(false);

    const wrapper = await mount();

    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(true);
    expect(wrapper.find("[data-test='canvas']").exists()).toBe(false);
    expect(wrapper.find(".cargo-grid-viewer__reset").exists()).toBe(false);
  });
});
