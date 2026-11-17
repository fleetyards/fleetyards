import { mountWithDefaults } from "@/shared/utils/TestUtils";

const webglAvailable = vi.hoisted(() => vi.fn(() => true));

vi.mock("@/shared/utils/Webgl", () => ({ webglAvailable }));

vi.mock("@tresjs/core", () => ({
  TresCanvas: { template: "<div data-test='canvas'><slot /></div>" },
  useLoop: () => ({ onBeforeRender: () => ({ off: () => undefined }) }),
  useTres: () => ({
    camera: { value: undefined },
    controls: { value: null },
    renderer: undefined,
  }),
}));

vi.mock("@tresjs/cientos", () => ({
  OrbitControls: { template: "<div />" },
  Html: { template: "<div />" },
}));

const { default: Starmap } = await import("./index.vue");

const mount = () => mountWithDefaults<typeof Starmap>(Starmap, {});

describe("Starmap", () => {
  beforeEach(() => {
    webglAvailable.mockReturnValue(true);
  });

  it("draws the map with its controls where WebGL works", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='canvas']").exists()).toBe(true);
    expect(wrapper.find("[data-test='starmap-reset']").exists()).toBe(true);
    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(false);
  });

  it("starts at the systems, with nothing selected", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[aria-current='page']").text()).toBe("Systems");
    expect(wrapper.find("[data-test='starmap-detail']").exists()).toBe(false);
  });

  it("says so where WebGL is missing, with nothing left to control", async () => {
    webglAvailable.mockReturnValue(false);

    const wrapper = await mount();

    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(true);
    expect(wrapper.find("[data-test='canvas']").exists()).toBe(false);
    expect(wrapper.find("[data-test='starmap-reset']").exists()).toBe(false);
  });
});
