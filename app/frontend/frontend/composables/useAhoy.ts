import ahoy from "ahoy.js";
import { START_LOCATION } from "vue-router";
import { useCookiesStore } from "@/frontend/stores/cookies";
import { useSessionStore } from "@/frontend/stores/session";
import { isInstalledApp } from "@/shared/utils/DisplayMode";

ahoy.configure({
  cookies: false,
});

let trackingAllowed = true;
let guarded = false;

// ahoy.js binds its submit listener permanently and offers no way to detach it,
// so the objection is enforced on the way out instead of at bind time. That way
// turning tracking off takes effect immediately rather than on the next reload.
const guardTrack = () => {
  if (guarded) {
    return;
  }
  guarded = true;

  const track = ahoy.track.bind(ahoy);

  ahoy.track = (name, properties) => {
    if (!trackingAllowed) {
      return false;
    }

    return track(name, properties);
  };
};

const trackView = () => {
  ahoy.trackView(isInstalledApp() ? { installed: true } : {});
};

export const useAhoy = () => {
  const router = useRouter();
  const sessionStore = useSessionStore();
  const cookiesStore = useCookiesStore();

  // Signed-in users carry the preference on their account so it follows them
  // between devices; guests only have the locally stored one.
  const allowed = computed(() =>
    sessionStore.authenticated
      ? sessionStore.currentUser?.tracking !== false
      : cookiesStore.trackingAccepted,
  );

  guardTrack();

  watch(
    allowed,
    (value) => {
      trackingAllowed = value;
    },
    { immediate: true },
  );

  trackView();
  ahoy.trackSubmits("form");

  // The view above covers the page the app was loaded on, so the initial
  // navigation is skipped. A change of query or hash alone (a modal, a tab, a
  // filter) stays on the same page and is not a new view.
  router.afterEach((to, from, failure) => {
    if (failure || from === START_LOCATION || to.path === from.path) {
      return;
    }

    // Lets the route's document title settle before ahoy.js reads it.
    void nextTick(trackView);
  });
};
