import { describe, expect, it, vi, beforeEach } from "vitest";
import { useVehicleImage } from "./useVehicleImage";
import type { MediaFile } from "@/services/fyApi";

const enabled = ref(true);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => enabled.value }),
}));

const upload = {
  name: "ship.jpg",
  mediumUrl: "https://example.test/ship.webp",
};

describe("useVehicleImage", () => {
  beforeEach(() => {
    enabled.value = true;
  });

  it("returns the owner's picture", () => {
    const { uploadedImage } = useVehicleImage();

    expect(uploadedImage({ image: upload as MediaFile })).toEqual(upload);
  });

  it("returns nothing for a ship without one", () => {
    const { uploadedImage } = useVehicleImage();

    expect(uploadedImage({})).toBeUndefined();
  });

  it("hides the picture while the feature is off", () => {
    enabled.value = false;

    const { uploadedImage } = useVehicleImage();

    expect(uploadedImage({ image: upload as MediaFile })).toBeUndefined();
  });
});
