import { useComlink } from "@/shared/composables/useComlink";

// Opening the support modal is an instruction anybody can put in an address:
// the login sends one back so the modal is where it was left, and a link can
// carry one on its own.
export const SUPPORT_QUERY_FLAG = "support";

// A repeated query parameter arrives as an array, and a bare `?support` as
// null, so the flag is only the value that was actually asked for.
function isFlagged(value: unknown) {
  return Array.isArray(value) ? value.includes("true") : value === "true";
}

export const useSupportModal = () => {
  const comlink = useComlink();
  const route = useRoute();

  const openSupportModal = () => {
    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/SupportBtn/Modal/index.vue"),
      wide: true,
    });
  };

  // The flag stays in the address: it says what is open, so a reload, a
  // bookmark and a copied link all land back on the same thing.
  const openFromQuery = () => {
    if (!isFlagged(route.query[SUPPORT_QUERY_FLAG])) return;

    openSupportModal();
  };

  // Where a login has to come back to for the support content to be here
  // again. The page shows it without a modal, so it only needs its own route;
  // everywhere else the modal has to be asked for.
  const supportReturnRoute = (standalone = false) =>
    standalone
      ? { name: "support" }
      : {
          path: route.path,
          query: { ...route.query, [SUPPORT_QUERY_FLAG]: "true" },
          hash: route.hash,
        };

  return { openSupportModal, openFromQuery, supportReturnRoute };
};
