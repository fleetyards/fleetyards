import type { RouterLinkProps } from "vue-router";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";

export const useRedirectBack = (fallbackRoute?: RouterLinkProps["to"]) => {
  const redirectBackStore = useRedirectBackStore();

  const router = useRouter();

  const handleRedirect = async () => {
    const backRoute = redirectBackStore.resolveBackRoute(router);

    if (backRoute) {
      await router.replace(backRoute);
    } else if (fallbackRoute) {
      await router.push(fallbackRoute).catch(() => {});
    } else {
      await router.push({ name: "home" }).catch(() => {});
    }

    redirectBackStore.$reset();
  };

  return {
    handleRedirect,
  };
};
