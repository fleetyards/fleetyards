<template>
  <nav
    ref="navigation"
    class="transition-nav ease-[ease] duration-500 absolute top-0 right-0 lg:top-auto lg:right-auto z-[1000] w-full lg:w-[300px] min-w-[300px] lg:h-screen"
    role="navigation"
  >
    <div
      class="transition-nav top-0 bottom-0 left-auto lg:top-auto lg:right-auto lg:bottom-auto ease-[ease] duration-500 lg:transition-none fixed w-[300px] min-w-[300px] lg:h-full lg:p-0 z-[1000] overflow-x-hidden overflow-y-auto bg-brand-grayBg/50 border-r border-brand-grayBorder/50"
      :class="[collapsed ? '-right-[300px]' : 'right-0']"
    >
      <div class="relative m-h-full flex flex-col justify-between">
        <ul class="py-5 mb-safe">
          <NavItem class="min-h-[60px]">
            <img v-lazy="logo" class="w-[40px]" alt="logo" />
            <span class="font-hero">
              {{ t("title.defaultDocsShort") }}
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
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import logo from "@/images/favicon-small.png";
import { useNavStore } from "@/docs/stores/nav";
import { storeToRefs } from "pinia";
import NavItem from "./NavItem/index.vue";

const navStore = useNavStore();

const { collapsed } = storeToRefs(navStore);

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
  // Store.commit("app/closeNav");
};
</script>

<script lang="ts">
export default {
  name: "AppNavigation",
};
</script>

<style lang="scss">
.app-navigation {
  transition:
    left ease 0.5s,
    right ease 0.5s,
    width ease 0.5s;
}

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
