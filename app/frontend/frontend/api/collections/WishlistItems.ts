import { get } from "@/frontend/api/client";

export class WishlistItemsCollection {
  records: string[] = [];

  async findAll(): Promise<string[]> {
    const response = await get<string[]>("wishlist/items", {}, true);

    if (!response.error) {
      this.records = response.data;
    }

    return this.records;
  }
}

export default new WishlistItemsCollection();
