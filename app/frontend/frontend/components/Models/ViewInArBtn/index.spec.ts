import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import type { Model } from "@/services/fyApi";

const mode = vi.hoisted(() => ({
  value: "scene-viewer" as string | undefined,
}));

vi.mock("@/frontend/utils/arViewer", () => ({
  arMode: () => mode.value,
  openInAr: vi.fn(),
}));

const { default: Component } = await import("./index.vue");

const model = (overrides: Partial<Model> = {}): Model =>
  ({
    slug: "sabre-raven",
    holoToScale: true,
    media: { holo: { url: "https://fleetyards.test/files/holo.glb" } },
    ...overrides,
  }) as Model;

const mount = (props: { model: Model }) =>
  mountWithDefaults<typeof Component>(Component, { props });

describe("ViewInArBtn", () => {
  it("offers AR for a holo exported to scale", async () => {
    mode.value = "scene-viewer";
    const wrapper = await mount({ model: model() });

    expect(wrapper.find('[data-test="view-in-ar"]').exists()).toBe(true);
  });

  it("hides AR for a holo that is not to scale", async () => {
    mode.value = "scene-viewer";
    const wrapper = await mount({ model: model({ holoToScale: false }) });

    expect(wrapper.find('[data-test="view-in-ar"]').exists()).toBe(false);
  });

  it("hides AR where the device has no AR viewer", async () => {
    mode.value = undefined;
    const wrapper = await mount({ model: model() });

    expect(wrapper.find('[data-test="view-in-ar"]').exists()).toBe(false);
  });
});
