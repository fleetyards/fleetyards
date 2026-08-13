import ahoy from "ahoy.js";
import { useCookiesStore } from "@/frontend/stores/cookies";
import { useSessionStore } from "@/frontend/stores/session";

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

export const useAhoy = () => {
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

  ahoy.trackView();
  ahoy.trackSubmits("form");
};
