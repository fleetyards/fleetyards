import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class RoadmapItemsCollection extends BaseCollection {
  primaryKey = "id";

  records: RoadmapItem[] = [];

  async ships(): Promise<RoadmapItem[]> {
    const response = await get("roadmap?ships=1", {
      q: {
        rsiCategoryIdIn: [6],
        activeEq: true,
      },
    });

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async overview(removed = false, released = false): Promise<RoadmapItem[]> {
    const response = await get("roadmap?overview=1", {
      q: {
        activeIn: [true, !removed],
        rsiReleaseIdGteq: released ? 41 : 1,
      },
    });

    if (!response.error) {
      return response.data;
    }

    return [];
  }
}

export default new RoadmapItemsCollection();
