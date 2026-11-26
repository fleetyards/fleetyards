import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import type { Model } from "@/services/fyApi";

vi.mock("@/shared/components/HoloViewer/Modal/index.vue", () => ({
  default: {
    name: "HoloViewerModal",
    props: { models: Array, suspended: Boolean },
    emits: ["unavailable"],
    template: "<div><slot name='groups' /><slot name='controls' /></div>",
  },
}));

vi.mock("@/frontend/components/Models/ViewInArBtn/index.vue", () => ({
  default: {
    name: "ViewInArBtn",
    props: { model: Object, active: Boolean, displayedHoloUrl: String },
    emits: ["quickLook", "quickLookEnd"],
    template: "<button />",
  },
}));

const { default: HoloModal } = await import("./index.vue");

const HOLO = "https://fleetyards.test/files/holo.glb";

const model = {
  slug: "sabre-raven",
  holoToScale: true,
  metrics: { length: 40, fleetchartOffsetLength: 40 },
  media: { holo: { url: HOLO } },
} as Model;

describe("ModelHoloModal", () => {
  it("offers AR for the holo it shows", async () => {
    const wrapper = await mountWithDefaults<typeof HoloModal>(HoloModal, {
      props: { model },
    });

    const ar = wrapper.findComponent({ name: "ViewInArBtn" });

    expect(ar.props("active")).toBe(true);
    expect(ar.props("displayedHoloUrl")).toBe(HOLO);
  });

  it("takes the 3D view down while Quick Look converts the holo", async () => {
    const wrapper = await mountWithDefaults<typeof HoloModal>(HoloModal, {
      props: { model },
    });

    const viewer = () => wrapper.findComponent({ name: "HoloViewerModal" });
    const ar = wrapper.findComponent({ name: "ViewInArBtn" });

    ar.vm.$emit("quickLook");
    await nextTick();

    expect(viewer().props("suspended")).toBe(true);

    ar.vm.$emit("quickLookEnd");
    await nextTick();

    expect(viewer().props("suspended")).toBe(false);
  });
});
