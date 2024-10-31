<template>
  <div
    class="navigation-mobile noselect transition-nav ease-[ease] duration-500"
    :class="[collapsed ? 'right-0' : 'right-[300px]']"
  >
    <div class="navigation-items">
      <!-- <Btn
        variant="link"
        size="large"
        :inline="true"
        :to="{ name: 'home' }"
        :class="{ active: routeActive('home') }"
        :exact="true"
      >
        <i class="fad fa-home-alt" />
      </Btn> -->
      <Btn variant="link" size="large" :inline="true" :to="{ name: 'api-v1' }">
        <i class="fad fa-books" />
      </Btn>
      <Btn variant="link" size="large" :inline="true" :to="{ name: 'embed' }">
        <i class="fad fa-arrow-up-from-square" />
      </Btn>
      <button
        :class="{
          collapsed: collapsed,
        }"
        class="nav-toggle"
        type="button"
        aria-label="Toggle Navigation"
        @click.stop.prevent="navStore.toggle"
      >
        <span class="sr-only">
          {{ t("labels.toggleNavigation") }}
        </span>
        <span class="icon-bar top-bar" />
        <span class="icon-bar middle-bar" />
        <span class="icon-bar bottom-bar" />
      </button>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useNavStore } from "@/docs/stores/nav";
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/docs/components/core/Btn/index.vue";

const { t } = useI18n();

const navStore = useNavStore();

const { collapsed } = storeToRefs(navStore);
</script>

<script lang="ts">
export default {
  name: "AppNavigationMobile",
};
</script>

<style lang="scss" scoped>
.navigation-mobile {
  position: fixed;
  bottom: 0;
  z-index: 1000;
  width: 100%;

  .navigation-items {
    display: flex;
    align-items: stretch;
    justify-content: space-between;
    min-height: $navigation-mobile-height;
    padding-bottom: $navigation-mobile-bottom-offset;
    background-color: rgba(darken($gray-darker, 7%), 0.95);
    border-top: 1px solid rgba(30, 34, 38, 0.5);

    .navigation-item-image {
      max-width: 24px;
      margin-right: 3px;
      margin-left: 3px;
      vertical-align: middle;
    }

    > button {
      flex-direction: column;
    }

    > * {
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
      width: 100%;
      min-height: $navigation-mobile-height;
      margin-right: 0;
      padding: 0;
      border-radius: 0;
      opacity: 0.9;

      &::after {
        position: absolute;
        top: 0;
        left: 10%;
        display: none;
        width: 80%;
        height: 3px;
        background: $primary;
        border-bottom-right-radius: 2px;
        border-bottom-left-radius: 2px;
        box-shadow: 2px 0 10px rgba(darken($primary, 20%), 0.9);
        content: "";
      }

      &.active {
        opacity: 1;

        &::after {
          display: block;
        }
      }
    }
  }
}
.nav-toggle {
  display: block;
  height: 43px;
  margin-right: 10px;
  padding: 0 11px;
  background-color: transparent;
  border: 1px solid transparent;
  border-color: transparent;
  border-radius: 3px;

  .icon-bar {
    display: block;
    width: 22px;
    height: 2px;
    background-color: #c8c8c8;
    border-radius: 1px;
    transition: all ease 0.2s;
  }

  .top-bar {
    transform: rotate(45deg);
    transform-origin: 10% 10%;
  }

  .middle-bar {
    margin-top: 4px;
    opacity: 0;
  }

  .bottom-bar {
    margin-top: 4px;
    transform: rotate(-45deg);
    transform-origin: 10% 90%;
  }

  .update-icon {
    position: absolute;
    top: 12px;
    right: 8px;
    width: 10px;
    height: 10px;
    background-color: $warning;
    border-radius: 50%;
    transition: all ease 0.5s;
  }

  &.collapsed {
    .top-bar,
    .bottom-bar {
      transform: rotate(0);
    }

    .middle-bar {
      opacity: 1;
    }
  }
}
</style>
