<script lang="ts">
export default {
  name: "AppNavigationBackButton",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useMediaQuery } from "@vueuse/core";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";

const { t } = useI18n();

const router = useRouter();

const route = useRoute();

// An installed app runs without the browser's toolbar, so a cross link (a
// component on a ship's page, say) would otherwise be a one-way trip: the
// breadcrumbs lead up the hierarchy, not back to where the link was.
const displayModeWithoutToolbar = useMediaQuery(
  "(display-mode: standalone), (display-mode: fullscreen)",
);

const iosHomeScreenApp =
  (navigator as Navigator & { standalone?: boolean }).standalone === true;

// `history.state` is not reactive; reading the route first re-evaluates this
// after every navigation, by which point the router has written the new entry.
// `back` is only set for entries this app pushed, so it never leaves the app.
const canGoBack = computed(
  () => !!route.fullPath && !!router.options.history.state.back,
);

const mobile = useMobile();

// A page that opts in has a way back on a phone even in the browser, where it
// stands in for the heading the page leaves out there. Reached directly, with
// nothing of this app's to go back to, it leads home.
const pageBack = computed(() => mobile.value && !!route.meta.mobileBack);

const visible = computed(
  () =>
    pageBack.value ||
    ((displayModeWithoutToolbar.value || iosHomeScreenApp) && canGoBack.value),
);

const back = () => {
  if (canGoBack.value) {
    router.back();
  } else {
    void router.push("/");
  }
};
</script>

<template>
  <Btn
    v-if="visible"
    :variant="BtnVariantsEnum.BARE"
    :aria-label="t('nav.back')"
    class="app-navigation-back-button"
    data-test="app-navigation-back"
    @click="back"
  >
    <i class="fa-light fa-chevron-left" />
  </Btn>
</template>
