import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { h } from "vue";

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

vi.mock("./Model/index.vue", () => ({
  default: {
    name: "HoloModel",
    props: ["model"],
    emits: ["error"],
    template: "<div data-test='model' />",
  },
}));

vi.mock("./RoomLighting/index.vue", () => ({
  default: { template: "<div />" },
}));

const reportError = vi.hoisted(() => vi.fn());

vi.mock("@/shared/plugins/Appsignal", () => ({ reportError }));

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

  describe("with its actions collapsed", () => {
    let mounted: { unmount: () => void } | undefined;

    // The menu is teleported to the body, so a wrapper left mounted leaves it
    // there for the next test.
    afterEach(() => {
      mounted?.unmount();
      mounted = undefined;
    });

    const mountCollapsed = async (fullscreen = false) => {
      mounted = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
        props: {
          models: [{ path: "/holo.gltf" }],
          collapseActions: true,
          grid: true,
          fullscreen,
        },
        slots: {
          actions: ({ inMenu }: { inMenu: boolean }) => [
            h(
              "button",
              { "data-test": "slot-action" },
              inMenu ? "in menu" : "in row",
            ),
          ],
        },
      });

      return mounted as Awaited<
        ReturnType<typeof mountWithDefaults<typeof HoloViewer>>
      >;
    };

    it("keeps the turn in the row and the rest in a menu", async () => {
      setViewport(false);
      const wrapper = await mountCollapsed();
      const menu = wrapper.find("[data-test='holo-viewer-menu']");
      const list = document.body.querySelector("[data-test='dropdown-list']");

      expect(menu.exists()).toBe(true);
      expect(menu.find("[data-test='holo-viewer-auto-rotate']").exists()).toBe(
        false,
      );
      expect(
        wrapper
          .find(".holo-viewer__actions [data-test='holo-viewer-auto-rotate']")
          .exists(),
      ).toBe(true);
      expect(list?.querySelector("[data-test='holo-viewer-auto-rotate']")).toBe(
        null,
      );
      expect(list?.querySelector("[data-test='holo-viewer-grid']")).not.toBe(
        null,
      );
      expect(
        list?.querySelector("[data-test='slot-action']")?.textContent,
      ).toBe("in menu");
    });

    it("lays the row out again in full screen", async () => {
      setViewport(false);
      const wrapper = await mountCollapsed(true);

      expect(wrapper.find("[data-test='holo-viewer-menu']").exists()).toBe(
        false,
      );
      expect(wrapper.find("[data-test='slot-action']").text()).toBe("in row");
    });
  });

  it("keeps its buttons clear of a phone's notch where it fills the screen", async () => {
    setViewport(false);
    const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
      props: { models: [{ path: "/holo.gltf" }], edgeToEdge: true },
    });

    expect(wrapper.find(".holo-viewer--edge-to-edge").exists()).toBe(true);
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

  describe("a holo that does not load", () => {
    const decoderAbort = {
      type: "error",
      error: "Aborted(). Build with -sASSERTIONS for more info.",
    };

    const full = {
      path: "/textured.glb",
      length: 20,
      size: MB,
      textured: true,
      paint: "/paint.webp",
      fallback: { path: "/textured_lite.glb", paint: "/paint_lite.webp" },
    };

    const shownPaths = (wrapper: Awaited<ReturnType<typeof mount>>) =>
      wrapper
        .findAllComponents({ name: "HoloModel" })
        .map((model) => (model.props("model") as { path: string }).path);

    const failModel = async (wrapper: Awaited<ReturnType<typeof mount>>) => {
      wrapper
        .findComponent({ name: "HoloModel" })
        .vm.$emit("error", decoderAbort);
      await wrapper.vm.$nextTick();
    };

    beforeEach(() => {
      setViewport(false);
      reportError.mockClear();
    });

    it("draws its fallback with the fallback's paint, quietly", async () => {
      const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
        props: { models: [full] },
      });

      await failModel(wrapper);

      const shown = wrapper.findComponent({ name: "HoloModel" });
      expect(shownPaths(wrapper)).toEqual(["/textured_lite.glb"]);
      expect(shown.props("model")).toMatchObject({
        textured: true,
        paint: "/paint_lite.webp",
      });
      expect(wrapper.emitted("unavailable")).toBeUndefined();
    });

    it("reports a decoder abort with the file it failed on", async () => {
      const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
        props: { models: [full] },
      });

      await failModel(wrapper);

      expect(reportError).toHaveBeenCalledOnce();
      expect(String(reportError.mock.calls[0][0])).toContain(
        "for more info. (/textured.glb)",
      );
    });

    it("gives up by the caller's path once the fallback fails too", async () => {
      const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
        props: { models: [full] },
      });

      await failModel(wrapper);
      await failModel(wrapper);

      expect(wrapper.emitted("unavailable")).toEqual([["/textured.glb"]]);
      expect(String(reportError.mock.calls[1][0])).toContain(
        "(/textured_lite.glb)",
      );
    });

    it("gives up straight away without a fallback", async () => {
      const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
        props: { models: [{ path: "/holo.glb", length: 20, size: MB }] },
      });

      await failModel(wrapper);

      expect(wrapper.emitted("unavailable")).toEqual([["/holo.glb"]]);
    });

    it("does not report a download that failed", async () => {
      const wrapper = await mountWithDefaults<typeof HoloViewer>(HoloViewer, {
        props: { models: [full] },
      });

      wrapper
        .findComponent({ name: "HoloModel" })
        .vm.$emit("error", new ProgressEvent("error"));
      await wrapper.vm.$nextTick();

      expect(reportError).not.toHaveBeenCalled();
      expect(shownPaths(wrapper)).toEqual(["/textured_lite.glb"]);
    });
  });
});
