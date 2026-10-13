import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("@/shared/utils/Webgl", () => ({ webglAvailable: () => true }));

vi.mock("@tresjs/core", () => ({
  TresCanvas: { name: "TresCanvas", template: "<div data-test='canvas' />" },
}));

vi.mock("@tresjs/cientos", () => ({
  OrbitControls: { template: "<div />" },
  TransformControls: { template: "<div />" },
  Grid: { template: "<div />" },
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
});
