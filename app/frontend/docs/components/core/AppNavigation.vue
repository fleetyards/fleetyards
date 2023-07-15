<template>
  <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col">
    <!-- Sidebar component, swap this element with another sidebar if you like -->
    <div
      class="flex grow flex-col gap-y-5 overflow-y-auto bg-gray-800 px-4 pb-4 pt-5"
    >
      <nav class="flex flex-1 flex-col">
        <ul role="list" class="flex flex-1 flex-col gap-y-7">
          <li>
            <ul role="list" class="-mx-2 space-y-1">
              <NavItem
                :to="{ name: 'home' }"
                :no-active="true"
                class="font-hero"
              >
                <template #icon>
                  <img
                    class="h-8 w-auto"
                    :src="logo"
                    alt="Fleetyards API Documentation"
                  />
                </template>
                {{ t("shortTitle") }}
              </NavItem>
              <NavItem :to="{ name: 'home' }" icon="fad fa-home-alt"
                >Home</NavItem
              >
              <NavItem :to="{ name: 'api-v1' }" icon="fad fa-books"
                >API V1</NavItem
              >
              <NavItem
                :to="{ name: 'embed' }"
                icon="fad fa-arrow-up-from-square"
                >Embed Widget</NavItem
              >
            </ul>
          </li>
        </ul>
      </nav>
    </div>
  </div>
</template>

<script lang="ts" setup>
import logo from "@/images/favicon.png";
import NavItem from "@/docs/components/core/AppNavigationItem.vue";
import { useI18n } from "@/docs/composables/useI18n";

const { t } = useI18n();
</script>

<script lang="ts">
export default {
  name: "AppNavigation",
};
</script>
