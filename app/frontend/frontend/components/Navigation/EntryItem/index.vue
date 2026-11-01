<script lang="ts">
export default {
  name: "AppNavigationEntryItem",
};
</script>

<script lang="ts" setup>
import NavItem from "@/shared/components/AppNavigation/NavItem/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNavFavorites } from "@/frontend/composables/useNavFavorites";
import {
  type NavEntry,
  isEntryActive,
} from "@/frontend/components/Navigation/entries";

type Props = {
  entry: NavEntry;
  // Off for a row whose page is reachable in one click anyway, like Home.
  pinnable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  pinnable: true,
});

const { t } = useI18n();

const route = useRoute();

const { isFavorite, toggle } = useNavFavorites();

const active = computed(() =>
  isEntryActive(props.entry, String(route.name ?? "")),
);

const favorite = computed(() => isFavorite(props.entry.key));

const toggleFavorite = () => {
  void toggle(props.entry.key);
};
</script>

<template>
  <NavItem
    :to="{ name: entry.route }"
    :menu-key="entry.key"
    :label="t(entry.labelKey)"
    :icon="entry.icon"
    :active="active"
    :pinnable="pinnable"
    :favorite="favorite"
    @toggle-favorite="toggleFavorite"
  />
</template>
