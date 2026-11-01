<script lang="ts">
export default {
  name: "AppNavigationFavoritesNav",
};
</script>

<script lang="ts" setup>
import EntryItem from "@/frontend/components/Navigation/EntryItem/index.vue";
import { useNavFavorites } from "@/frontend/composables/useNavFavorites";
import { useSessionStore } from "@/frontend/stores/session";
import { useNavStore } from "@/shared/stores/nav";
import { useI18n } from "@/shared/composables/useI18n";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const { favorites, adoptGuestFavorites } = useNavFavorites();

const { slimNavigation } = storeToRefs(useNavStore());

const { currentUser } = storeToRefs(useSessionStore());

// Keyed on the account rather than the flag, so switching accounts without a
// reload still hands the guest list to the one that signed in.
watch(
  () => currentUser.value?.id,
  () => {
    adoptGuestFavorites();
  },
  { immediate: true },
);
</script>

<template>
  <template v-if="favorites.length">
    <li
      class="nav-item__heading"
      :class="{ 'nav-item__heading--slim': slimNavigation }"
      data-test="nav-favorites-heading"
    >
      {{ t("nav.favorites.index") }}
    </li>
    <EntryItem
      v-for="entry in favorites"
      :key="`favorite-${entry.key}`"
      :entry="entry"
    />
    <li class="nav-item__divider" />
  </template>
</template>
