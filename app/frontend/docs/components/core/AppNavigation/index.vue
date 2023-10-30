<template>
  <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col">
    <nav
      ref="navigation"
      class="relative w-[300px] min-w-[300px] h-screen z-[1000]"
      role="navigation"
    >
      <div
        class="nav-container fixed w-[300px] h-full overflow-y-auto overflow-x-hidden bg-brand-grayBg/50 border-r border-brand-grayBorder/50 fir"
      >
        <div class="relative min-h-full flex flex-col justify-between">
          <ul class="py-5 mb-safe">
            <NavItem class="min-h-[60px]">
              <img v-lazy="logo" class="w-[40px]" alt="logo" />
              <span class="font-hero">
                {{ t("shortTitle") }}
              </span>
            </NavItem>
            <NavItem
              :to="{ name: 'api-v1' }"
              :label="t('nav.apiV1')"
              icon="fad fa-books"
            />
            <NavItem
              :to="{ name: 'embed' }"
              :label="t('nav.embed')"
              icon="fad fa-arrow-up-from-square"
            />
          </ul>
        </div>
      </div>
    </nav>
  </div>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import Store from "@/frontend/lib/Store";
import { useI18n } from "@/docs/composables/useI18n";
import logo from "@/images/favicon-small.png";
import NavItem from "./NavItem/index.vue";

const { t } = useI18n();

const route = useRoute();

watch(
  () => route.path,
  () => {
    close();
  },
);

onMounted(() => {
  document.addEventListener("click", documentClick);
});

onBeforeUnmount(() => {
  document.removeEventListener("click", documentClick);

  close();
});

const navigation = ref<HTMLElement | null>(null);

const documentClick = (event: Event) => {
  const element = navigation.value;
  const { target } = event;

  if (element !== target && !element?.contains(target as Node)) {
    close();
  }
};

const close = () => {
  Store.commit("app/closeNav");
};
</script>

<script lang="ts">
export default {
  name: "AppNavigation",
};
</script>

<style lang="scss">
nav {
  .nav-container {
    // a {
    //   transition: none;
    // }

    .logo-menu {
      min-height: 60px;

      .logo-menu-image {
        position: absolute;
        top: 10px;
        left: 20px;
        width: 40px;
      }

      .logo-menu-label {
        display: block;
        padding-top: 6px;
        padding-right: 20px;
        padding-left: 50px;
        font-family: "Orbitron", sans-serif;
      }
    }
  }
}
</style>
