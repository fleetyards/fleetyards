import { mountWithDefaults } from "@/shared/utils/TestUtils";

const webglAvailable = vi.hoisted(() => vi.fn(() => true));

vi.mock("@/shared/utils/Webgl", () => ({ webglAvailable }));

const mobile = await vi.hoisted(async () => {
  const { ref } = await import("vue");
  return ref(false);
});

vi.mock("@/shared/composables/useMobile", () => ({ useMobile: () => mobile }));

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
  // The map's view controls go into the app's header.
  beforeEach(() => {
    mobile.value = false;
    webglAvailable.mockReturnValue(true);
    document.body.innerHTML = '<div id="header-right"></div>';
  });

  const inHeader = (selector: string) =>
    document.querySelector(`#header-right ${selector}`);

  it("draws the map with its controls where WebGL works", async () => {
    const wrapper = await mount();

    expect(wrapper.find("[data-test='canvas']").exists()).toBe(true);
    expect(inHeader("[data-test='starmap-reset']")).not.toBeNull();
    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(false);
  });

  it("keeps the controls on the map where a phone's header has no room", async () => {
    mobile.value = true;

    const wrapper = await mount();

    expect(inHeader("[data-test='starmap-reset']")).toBeNull();
    expect(wrapper.find("[data-test='starmap-reset']").exists()).toBe(true);
  });

  it("starts at the systems, with nothing selected", async () => {
    const wrapper = await mount();

    expect(wrapper.text()).toContain("Systems");
    expect(wrapper.find("[data-test='starmap-detail']").exists()).toBe(false);
  });

  it("says so where WebGL is missing, with nothing left to control", async () => {
    webglAvailable.mockReturnValue(false);

    const wrapper = await mount();

    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(true);
    expect(wrapper.find("[data-test='canvas']").exists()).toBe(false);
    expect(inHeader("[data-test='starmap-reset']")).toBeNull();
  });
});
