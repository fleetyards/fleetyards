<script lang="ts">
export default {
  name: "AppNavigationAccountMenu",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import NavMenu from "@/shared/components/AppNavigation/NavMenu/index.vue";
import NavMenuItem from "@/shared/components/AppNavigation/NavMenu/Item/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useSessionStore } from "@/frontend/stores/session";
import { useNavContextStore } from "@/frontend/stores/navContext";
import { usePendingFriendRequests } from "@/frontend/composables/usePendingFriendRequests";
import {
  useCart,
  useNotificationsUnreadCount as useNotificationsUnreadCountQuery,
} from "@/services/fyApi";
import rsiLogo from "@/images/rsi_logo.png";

type Props = {
  showInstall?: boolean;
};

withDefaults(defineProps<Props>(), {
  showInstall: false,
});

const emit = defineEmits<{
  install: [];
}>();

const { t } = useI18n();

const router = useRouter();

const route = useRoute();

const sessionStore = useSessionStore();

const { currentUser } = storeToRefs(sessionStore);

// The cable subscription in `useUpdates` invalidates this on every arriving
// notification; the interval only covers what expired or was read elsewhere.
const { data: unreadCount } = useNotificationsUnreadCountQuery({
  query: { refetchInterval: 60_000 },
});

const unread = computed(() => unreadCount.value?.count || 0);

// Friend requests are answered two levels in, under settings, so the settings
// row carries their count.
const { count: pendingFriendRequests } = usePendingFriendRequests();

// What wants the reader's attention while the menu is shut. A full cart is not
// that, so its count stays on its own row.
const attention = computed(() => unread.value + pendingFriendRequests.value);

const attentionLabel = computed(() =>
  attention.value > 99 ? "99+" : String(attention.value),
);

// Shares the cart page's query, so an edit there or an item added from a
// catalogue moves the count without a request of its own.
const { data: cart } = useCart();

const cartCount = computed(() => cart.value?.totals.quantity || 0);

const settingsActive = computed(() =>
  String(route.name ?? "").startsWith("settings"),
);

const navContextStore = useNavContextStore();

const logout = () => {
  // The next account to sign in on this browser starts in its own hangar.
  navContextStore.$reset();
  void sessionStore.logout();
  void router.replace({ name: "login" });
};
</script>

<template>
  <NavMenu v-if="currentUser" placement="up" data-test="user-menu">
    <template #trigger="{ slim }">
      <span class="account-menu__avatar">
        <img
          v-if="currentUser.avatar?.smallUrl"
          :src="currentUser.avatar.smallUrl"
          alt=""
        />
        <span v-else class="account-menu__initial">
          {{ currentUser.username.charAt(0) }}
        </span>
        <span
          v-if="attention"
          class="account-menu__badge"
          aria-hidden="true"
          data-test="user-menu-badge"
        >
          {{ attentionLabel }}
        </span>
      </span>
      <span class="sr-only">{{ t("nav.account.menu") }}:</span>
      <span class="account-menu__name" :class="{ 'sr-only': slim }">
        {{ currentUser.username }}
      </span>
      <span v-if="attention" class="sr-only">
        ({{ t("nav.account.unread", { count: attention }) }})
      </span>
      <i
        v-if="!slim"
        class="account-menu__chevron fa-light fa-chevron-up"
        aria-hidden="true"
      />
    </template>

    <NavMenuItem
      :to="{ name: 'notifications' }"
      :label="t('nav.notifications')"
      icon="fa-light fa-bell"
      :badge="unread"
      :active="route.name === 'notifications'"
      data-test="nav-notifications"
    />
    <NavMenuItem
      :to="{ name: 'cart' }"
      :label="t('nav.cart')"
      icon="fa-light fa-cart-shopping"
      :count="cartCount"
      :active="route.name === 'cart'"
      data-test="cart-nav"
    />
    <NavMenuItem divider />
    <NavMenuItem
      :to="{ name: 'settings' }"
      :label="t('nav.settings.index')"
      icon="fa-light fa-cog"
      :badge="pendingFriendRequests"
      :active="settingsActive"
      data-test="nav-settings"
    />
    <NavMenuItem
      v-if="currentUser.rsiHandle"
      :href="`https://robertsspaceindustries.com/citizens/${currentUser.rsiHandle}`"
      :label="t('nav.rsiProfile')"
      :image="rsiLogo"
      data-test="nav-rsi-profile"
    />
    <NavMenuItem
      v-if="showInstall"
      :action="() => emit('install')"
      :label="t('nav.installApp')"
      icon="fa-light fa-mobile-screen"
      data-test="install-app"
    />
    <NavMenuItem divider />
    <NavMenuItem
      :action="logout"
      :label="t('nav.logout')"
      icon="fa-light fa-sign-out"
      data-test="nav-logout"
    />
  </NavMenu>
</template>

<style lang="scss" scoped>
@import "index";
</style>
