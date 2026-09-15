import type { Mission, MissionExtended } from "@/services/fyApi";
import fallback from "@/images/fallback/store_image.webp";
import { presetImageUrl } from "@/shared/composables/usePresetImages";

type CoverImageHolder = {
  mediumUrl?: string;
  smallUrl?: string;
  url?: string;
};

type MissionLike =
  | Mission
  | MissionExtended
  | {
      category?: string;
      coverImage?: CoverImageHolder | null;
      coverImagePreset?: string | null;
    };

export const useMissionCover = () => {
  /*
   * The picture the mission actually carries, then the one somebody picked for
   * it, then the art its category ships with -- the same order the picker in
   * the form keeps, so what a reader sees is what the author chose.
   */
  const resolve = (mission?: MissionLike | null) => {
    if (!mission) return fallback;

    const uploaded = (mission as { coverImage?: CoverImageHolder | null })
      .coverImage;
    if (uploaded) {
      return (
        uploaded.mediumUrl || uploaded.smallUrl || uploaded.url || fallback
      );
    }

    const preset = (mission as { coverImagePreset?: string | null })
      .coverImagePreset;

    return (
      presetImageUrl("missions", preset) ??
      presetImageUrl("missions", mission.category as string) ??
      fallback
    );
  };

  return { resolve };
};
