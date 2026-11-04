import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";

const webglAvailable = vi.hoisted(() => vi.fn(() => true));

vi.mock("@/shared/utils/Webgl", () => ({ webglAvailable }));

vi.mock("@tresjs/core", () => ({
  TresCanvas: {
    name: "TresCanvas",
    template: "<div data-test='canvas'><slot /></div>",
  },
}));

vi.mock("@tresjs/cientos", () => ({
  OrbitControls: { template: "<div />" },
  TransformControls: { template: "<div />" },
  Grid: { template: "<div />" },
  Stars: { template: "<div />" },
}));

vi.mock("./Model/index.vue", () => ({ default: { template: "<div />" } }));

const { default: HoloViewer } = await import("./index.vue");

const MB = 1_000_000;

const setViewport = (phone: boolean) => {
  window.matchMedia = ((query: string) => ({
    matches: phone,
    media: query,
    addEventListener: () => {},
    removeEventListener: () => {},
  })) as unknown as typeof window.matchMedia;
};

const mount = (size: number) =>
  mountWithDefaults<typeof HoloViewer>(HoloViewer, {
    props: { models: [{ path: "/holo.gltf", length: 20, size }] },
  });

describe("HoloViewer", () => {
  beforeEach(() => {
    setViewport(true);
    webglAvailable.mockReturnValue(true);
  });

  it("tells its parent where the probe finds no WebGL", async () => {
    webglAvailable.mockReturnValue(false);

    const wrapper = await mount(MB);

    expect(wrapper.find("[data-test='webgl-fallback']").exists()).toBe(true);
    expect(wrapper.find("[data-test='canvas']").exists()).toBe(false);
    expect(wrapper.emitted("unavailable")).toHaveLength(1);
  });

  it("asks a phone before loading a holo past the limit", async () => {
    const wrapper = await mount(40 * MB);

    expect(
      wrapper.find("[data-test='holo-viewer-too-large']").text(),
    ).toContain("40");
    expect(wrapper.find("[data-test='canvas']").exists()).toBe(false);
  });

  it("loads it once the phone says so", async () => {
    const wrapper = await mount(40 * MB);

    await wrapper
      .find("[data-test='holo-viewer-load-anyway']")
      .trigger("click");

    expect(wrapper.find("[data-test='canvas']").exists()).toBe(true);
  });

  it("loads a holo under the limit straight away", async () => {
    const wrapper = await mount(12 * MB);

    expect(wrapper.find("[data-test='holo-viewer-too-large']").exists()).toBe(
      false,
    );
    expect(wrapper.find("[data-test='canvas']").exists()).toBe(true);
  });

  it("counts the mounted parts towards the size a phone is asked about", async () => {
    const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
      props: {
        models: [
          {
            path: "/body.glb",
            size: 10 * MB,
            mounts: [
              {
                position: [0, 0, 0],
                rotation: [0, 0, 0, 1],
                path: "/core.glb",
                size: 15 * MB,
                mounts: [],
              },
              {
                position: [0, 0, 0],
                rotation: [0, 0, 0, 1],
                path: "/legs.glb",
                size: 15 * MB,
                mounts: [],
              },
            ],
          },
        ],
      },
    });

    expect(
      wrapper.find("[data-test='holo-viewer-too-large']").text(),
    ).toContain("40");
  });

  it("leaves full screen on Escape, opened full screen from the start", async () => {
    setViewport(false);
    const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
      props: { models: [{ path: "/holo.gltf" }], fullscreen: true },
    });

    window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
    await nextTick();

    expect(wrapper.find(".holo-viewer--fullscreen").exists()).toBe(false);
  });

  it("closes full screen from a labelled button", async () => {
    setViewport(false);
    const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
      props: { models: [{ path: "/holo.gltf" }], fullscreen: true },
    });

    const close = wrapper.find("[data-test='holo-viewer-close']");

    expect(close.classes()).toContain("btn--solid");
    expect(close.attributes("aria-label")).toBe("Close");

    await close.trigger("click");

    expect(wrapper.find(".holo-viewer--fullscreen").exists()).toBe(false);
  });

  it("never asks a desktop", async () => {
    setViewport(false);

    const wrapper = await mount(180 * MB);

    expect(wrapper.find("[data-test='canvas']").exists()).toBe(true);
  });

  it("keeps the answer for a holo no larger than the one agreed to", async () => {
    const wrapper = await mount(40 * MB);

    await wrapper
      .find("[data-test='holo-viewer-load-anyway']")
      .trigger("click");
    await wrapper.setProps({
      models: [{ path: "/landed.gltf", length: 20, size: 38 * MB }],
    });

    expect(wrapper.find("[data-test='canvas']").exists()).toBe(true);
  });

  it("asks again for a larger holo", async () => {
    const wrapper = await mount(40 * MB);

    await wrapper
      .find("[data-test='holo-viewer-load-anyway']")
      .trigger("click");
    await wrapper.setProps({
      models: [{ path: "/other.gltf", length: 20, size: 120 * MB }],
    });

    expect(wrapper.find("[data-test='holo-viewer-too-large']").exists()).toBe(
      true,
    );
  });

  // New camera args rebuild the camera with a fresh uuid, and the orbit
  // controls keyed by it come back without their change listener.
  it("sets the camera's planes as properties, never as args", async () => {
    setViewport(false);

    const wrapper = await mount(12 * MB);
    const camera = wrapper.find("TresPerspectiveCamera");

    expect(camera.attributes("args")).toBeUndefined();
    expect(camera.attributes()).toEqual(
      expect.objectContaining({ fov: "35", near: expect.any(String) }),
    );
  });
});
