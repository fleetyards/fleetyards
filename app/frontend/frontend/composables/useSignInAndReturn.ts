import { useRedirectBackStore } from "@/shared/stores/redirectBack";

// Sends a visitor to sign in and, once they have, back to this page as it
// is now, its query included. Login returns to the stored back route; a
// public page sets none on its own.
export const useSignInAndReturn = () => {
  const route = useRoute();
  const router = useRouter();
  const redirectBackStore = useRedirectBackStore();

  return async () => {
    redirectBackStore.setBackRoute(route.fullPath);
    await router.push({ name: "login" });
  };
};
