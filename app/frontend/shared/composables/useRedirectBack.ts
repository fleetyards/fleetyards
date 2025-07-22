import type { RouterLinkProps } from "vue-router";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";

export const useRedirectBack = (fallbackRoute?: RouterLinkProps["to"]) => {
  const redirectBackStore = useRedirectBackStore();

  const router = useRouter();

  const handleRedirect = async () => {
    redirectBackStore.backRoute;

    if (redirectBackStore.backRoute) {
      await router.replace(redirectBackStore.backRoute);
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
