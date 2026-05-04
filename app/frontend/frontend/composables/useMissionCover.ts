import type { Mission, MissionExtended } from "@/services/fyApi";
import fallback from "@/images/fallback/store_image.webp";

const covers = import.meta.glob<{ default: string }>(
  "@/images/missions/*.{webp,jpg,jpeg,png}",
  { eager: true },
);

const coverByCategory: Record<string, string> = {};

for (const [path, mod] of Object.entries(covers)) {
  const match = path.match(/missions\/([^./]+)\./);
  if (match) {
    coverByCategory[match[1]] = mod.default;
  }
}

type CoverImageHolder = {
  mediumUrl?: string;
  smallUrl?: string;
  url?: string;
};

export const useMissionCover = () => {
  const resolve = (mission?: Mission | MissionExtended | null) => {
    if (!mission) return fallback;

    const uploaded = (mission as { coverImage?: CoverImageHolder | null })
      .coverImage;
    if (uploaded) {
      return (
        uploaded.mediumUrl || uploaded.smallUrl || uploaded.url || fallback
      );
    }

    return coverByCategory[mission.category] || fallback;
  };

  return { resolve };
};
