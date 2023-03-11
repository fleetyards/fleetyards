import { get } from "@/frontend/api/client";

export class VersionCollection {
  record: TVersion | null = null;

  async current(): Promise<TVersion | null> {
    const response = await get<TVersion>("version", {}, true);

    if (!response.error) {
      this.record = response.data;
    }

    return this.record;
  }
}

export default new VersionCollection();
