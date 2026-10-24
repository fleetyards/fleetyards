import type { RouterLinkProps } from "vue-router";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";

export const useRedirectBack = (fallbackRoute?: RouterLinkProps["to"]) => {
  const redirectBackStore = useRedirectBackStore();

  const router = useRouter();

  const handleRedirect = async () => {
    const backRoute = redirectBackStore.backRoute;

    // Reset first: a persisted back route can name a route that no longer
    // exists, and the throw would otherwise keep it around for every login.
    redirectBackStore.$reset();

    if (backRoute) {
      try {
        await router.replace(backRoute);
        return;
      } catch {
        // fall through to the fallback
      }
    }

    await router.push(fallbackRoute ?? { name: "home" }).catch(() => {});
  };

  return {
    handleRedirect,
  };
};
