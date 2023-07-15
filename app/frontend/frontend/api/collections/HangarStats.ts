import { useApiClient } from "@/frontend/composables/useApiClient";
import { HangarStats } from "@/services/fyApi/models/HangarStats";
import type { HangarParams } from "@/frontend/api/collections/Hangar";

const { hangarStats } = useApiClient();

export class HangarStatsCollection {
  async get(params: HangarParams | null): Promise<HangarStats | undefined> {
    try {
      return await hangarStats.get({
        q: params?.filters,
      });
    } catch (error) {
      console.error(error);

      return undefined;
    }
  }
}

export default new HangarStatsCollection();
