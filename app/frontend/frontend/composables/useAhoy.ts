import { watch } from "vue";
import ahoy from "ahoy.js";
import { useCookiesStore } from "@/frontend/stores/Cookies";

ahoy.configure({
  cookies: false,
});

const setupAhoy = () => {
  ahoy.trackView();
  // ahoy.trackClicks()
  ahoy.trackSubmits("form");
};

export const useAhoy = () => {
  const cookiesStore = useCookiesStore();

  if (cookiesStore.ahoyAccepted) {
    setupAhoy();
  }

  watch(
    () => cookiesStore.ahoyAccepted,
    () => {
      if (cookiesStore.ahoyAccepted) {
        setupAhoy();
      } else {
        window.location.reload();
      }
    }
  );
};
