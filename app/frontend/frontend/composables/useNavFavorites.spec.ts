import { describe, expect, it, vi, beforeEach } from "vitest";
import { createTestingPinia } from "@pinia/testing";
import { setActivePinia } from "pinia";
import { useSessionStore } from "@/frontend/stores/session";
import { useNavFavoritesStore } from "@/frontend/stores/navFavorites";

const { updateProfile, displayAlert } = vi.hoisted(() => ({
  updateProfile: vi.fn(),
  displayAlert: vi.fn(),
}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  updateProfile,
}));
vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => false }),
}));
vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayAlert }),
}));

import {
  NAV_FAVORITES_LIMIT,
  useNavFavorites,
} from "@/frontend/composables/useNavFavorites";

const signIn = (navFavorites: string[]) => {
  const session = useSessionStore();

  session.authenticated = true;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  session.currentUser = { id: "user-1", navFavorites } as any;

  return session;
};

describe("useNavFavorites", () => {
  beforeEach(() => {
    setActivePinia(createTestingPinia());
    updateProfile.mockReset();
    displayAlert.mockReset();
  });

  it("keeps a guest's favorites in the browser", async () => {
    const { toggle, favorites } = useNavFavorites();

    await toggle("trade-routes");

    expect(useNavFavoritesStore().guestKeys).toEqual(["trade-routes"]);
    expect(favorites.value.map((entry) => entry.key)).toEqual(["trade-routes"]);
    expect(updateProfile).not.toHaveBeenCalled();
  });

  it("saves a signed-in reader's favorites to the account", async () => {
    signIn(["ships"]);
    updateProfile.mockResolvedValue({
      navFavorites: ["ships", "trade-routes"],
    });

    const { toggle, isFavorite } = useNavFavorites();

    await toggle("trade-routes");

    expect(updateProfile).toHaveBeenCalledWith({
      navFavorites: ["ships", "trade-routes"],
    });
    expect(isFavorite("trade-routes")).toBe(true);
  });

  it("unpins a page that is pinned", async () => {
    signIn(["ships", "trade-routes"]);
    updateProfile.mockResolvedValue({ navFavorites: ["ships"] });

    const { toggle } = useNavFavorites();

    await toggle("trade-routes");

    expect(updateProfile).toHaveBeenCalledWith({ navFavorites: ["ships"] });
  });

  it("puts the list back and says so when saving fails", async () => {
    const session = signIn(["ships"]);
    updateProfile.mockRejectedValue(new Error("offline"));
    vi.spyOn(console, "error").mockImplementation(() => {});

    const { toggle } = useNavFavorites();

    await toggle("trade-routes");

    expect(session.currentUser?.navFavorites).toEqual(["ships"]);
    expect(displayAlert).toHaveBeenCalled();
  });

  it("drops keys no page answers to any more when the list is saved", async () => {
    signIn(["renamed-page", "ships"]);
    updateProfile.mockResolvedValue({ navFavorites: ["ships", "compare"] });

    const { toggle, favorites } = useNavFavorites();

    expect(favorites.value.map((entry) => entry.key)).toEqual(["ships"]);

    await toggle("compare");

    expect(updateProfile).toHaveBeenCalledWith({
      navFavorites: ["ships", "compare"],
    });
  });

  it("hides a pinned page the reader cannot open", () => {
    signIn(["hangar-plans", "ships"]);

    const { favorites } = useNavFavorites();

    expect(favorites.value.map((entry) => entry.key)).toEqual(["ships"]);
  });

  it("stops at the limit", async () => {
    const pinned = [
      "home",
      "hangar",
      "hangar-wishlist",
      "hangar-stats",
      "hangar-blueprints",
      "hangar-inventories",
      "hangar-paints",
      "hangar-flair",
      "hangar-equipment",
      "hangar-ship-components",
      "hangar-upgrades",
      "hangar-buybacks",
      "ships",
      "compare",
      "images",
      "locations",
      "tools",
      "travel-times",
      "tours",
      "cargo-grids",
    ];
    expect(pinned).toHaveLength(NAV_FAVORITES_LIMIT);
    signIn(pinned);

    const { toggle } = useNavFavorites();

    await toggle("trade-routes");

    expect(updateProfile).not.toHaveBeenCalled();
    expect(displayAlert).toHaveBeenCalled();
  });

  it("hands a guest's list to an account that has none yet", () => {
    useNavFavoritesStore().guestKeys = ["trade-routes"];
    signIn([]);
    updateProfile.mockResolvedValue({ navFavorites: ["trade-routes"] });

    useNavFavorites().adoptGuestFavorites();

    expect(updateProfile).toHaveBeenCalledWith({
      navFavorites: ["trade-routes"],
    });
    expect(useNavFavoritesStore().guestKeys).toEqual([]);
  });

  it("never overwrites a list the account already has", () => {
    useNavFavoritesStore().guestKeys = ["trade-routes"];
    signIn(["ships"]);

    useNavFavorites().adoptGuestFavorites();

    expect(updateProfile).not.toHaveBeenCalled();
    expect(useNavFavoritesStore().guestKeys).toEqual([]);
  });
});
