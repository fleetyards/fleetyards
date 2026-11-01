import { storeToRefs } from "pinia";
import { updateProfile } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useNavFavoritesStore } from "@/frontend/stores/navFavorites";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type NavEntry,
  findNavEntry,
} from "@/frontend/components/Navigation/entries";

// The server caps the list at the same length.
export const NAV_FAVORITES_LIMIT = 20;

/*
 * Several toggles in quick succession each send the whole list, and their
 * answers can come back in any order. Only the answer to the newest request is
 * allowed to replace the list, or an older one would undo a newer click.
 */
let latestRequest = 0;

export const useNavFavorites = () => {
  const { t } = useI18n();

  const { displayAlert } = useAppNotifications();

  const sessionStore = useSessionStore();

  const { isAuthenticated, currentUser } = storeToRefs(sessionStore);

  const favoritesStore = useNavFavoritesStore();

  const { guestKeys } = storeToRefs(favoritesStore);

  const { isFeatureEnabled } = useFeatures();

  const keys = computed<string[]>(() =>
    isAuthenticated.value
      ? (currentUser.value?.navFavorites ?? [])
      : guestKeys.value,
  );

  const isVisible = (entry: NavEntry) => {
    if (entry.requiresAuth && !isAuthenticated.value) {
      return false;
    }

    return !entry.featureFlag || isFeatureEnabled(entry.featureFlag);
  };

  // A key nobody knows any more -- a page that was renamed or removed -- is left
  // out rather than rendered as a dead row. It stays stored, and is dropped the
  // next time the list is saved.
  const favorites = computed(() =>
    keys.value
      .map((key) => findNavEntry(key))
      .filter((entry): entry is NavEntry => !!entry && isVisible(entry)),
  );

  const isFavorite = (key: string) => keys.value.includes(key);

  const save = async (next: string[]) => {
    if (!isAuthenticated.value || !currentUser.value) {
      favoritesStore.guestKeys = next;

      return;
    }

    const previous = currentUser.value.navFavorites ?? [];
    const request = ++latestRequest;

    // Applied straight away, so the star answers the click rather than the
    // round trip.
    sessionStore.currentUser = { ...currentUser.value, navFavorites: next };

    try {
      const user = await updateProfile({ navFavorites: next });

      if (request === latestRequest && sessionStore.currentUser) {
        sessionStore.currentUser = {
          ...sessionStore.currentUser,
          navFavorites: user.navFavorites,
        };
      }
    } catch (error) {
      console.error(error);

      if (request === latestRequest && sessionStore.currentUser) {
        sessionStore.currentUser = {
          ...sessionStore.currentUser,
          navFavorites: previous,
        };
      }

      displayAlert({ text: t("messages.navFavorites.failure") });
    }
  };

  const toggle = (key: string) => {
    if (!findNavEntry(key)) {
      return Promise.resolve();
    }

    // Unknown keys are dropped here, so a renamed page does not hold a slot.
    const known = keys.value.filter((stored) => !!findNavEntry(stored));

    if (known.includes(key)) {
      return save(known.filter((stored) => stored !== key));
    }

    if (known.length >= NAV_FAVORITES_LIMIT) {
      displayAlert({
        text: t("messages.navFavorites.limit", { count: NAV_FAVORITES_LIMIT }),
      });

      return Promise.resolve();
    }

    return save([...known, key]);
  };

  /*
   * What a guest pinned is handed to the account they sign in to -- once, and
   * only to an account that has none of its own yet, so signing in never
   * overwrites a list that was set up elsewhere. The guest list is cleared
   * either way, so the next person to sign in on this browser does not inherit
   * it.
   */
  const adoptGuestFavorites = () => {
    if (!isAuthenticated.value || !currentUser.value) {
      return;
    }

    const pending = guestKeys.value.filter((key) => !!findNavEntry(key));

    favoritesStore.guestKeys = [];

    if (!pending.length || currentUser.value.navFavorites?.length) {
      return;
    }

    void save(pending.slice(0, NAV_FAVORITES_LIMIT));
  };

  return {
    favorites,
    isFavorite,
    toggle,
    adoptGuestFavorites,
  };
};
