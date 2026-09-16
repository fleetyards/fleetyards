import { useComlink } from "@/shared/composables/useComlink";
import type { AppModalOptions } from "@/shared/components/AppModal/types";

// `?modal=<name>` is what opens a modal that belongs to no record: a login
// comes back carrying one so the visitor lands where they left off, a link can
// carry one on its own, and a button that opens one writes it.
export const MODAL_QUERY_PARAM = "modal";

// The modals a URL is allowed to open. A modal belongs here when it needs
// nothing but itself -- most of the app's modals are about a record and are
// told which one by the caller, and a name in an address cannot say that.
export const QUERY_MODALS = {
  support: {
    component: () => import("@/frontend/components/SupportBtn/Modal/index.vue"),
    wide: true,
  },
} satisfies Record<string, AppModalOptions>;

export type QueryModalName = keyof typeof QUERY_MODALS;

// A repeated parameter arrives as an array and a bare `?modal` as null, and an
// unknown name is somebody's typo rather than an instruction -- so the answer
// is only ever a modal that exists.
function requestedModal(value: unknown): QueryModalName | undefined {
  const name = Array.isArray(value) ? value[0] : value;

  return typeof name === "string" && name in QUERY_MODALS
    ? (name as QueryModalName)
    : undefined;
}

export const useModalQuery = () => {
  const comlink = useComlink();
  const route = useRoute();
  const router = useRouter();

  // This page, with the modal asked for -- where a login has to come back to
  // for the visitor to find what they left.
  const modalRoute = (name: QueryModalName) => ({
    path: route.path,
    query: { ...route.query, [MODAL_QUERY_PARAM]: name },
    hash: route.hash,
  });

  // Writing the name into the address is the whole of opening one: the app
  // watches the address and puts up what it names. So the URL always says what
  // is open, whether the visitor clicked a button, followed a link, or came
  // back from a login -- and there is only ever one way in.
  const openModal = async (name: QueryModalName) => {
    if (requestedModal(route.query[MODAL_QUERY_PARAM]) === name) return;

    await router.replace(modalRoute(name));
  };

  const openFromQuery = () => {
    const name = requestedModal(route.query[MODAL_QUERY_PARAM]);

    if (!name) return;

    comlink.emit("open-modal", QUERY_MODALS[name]);
  };

  // Closing is the other half: the address stops saying a modal is open. It
  // runs for every modal, not only the ones named here, so whatever is in the
  // address when an unrelated modal closes is cleared with it.
  const clearModalQuery = async () => {
    if (route.query[MODAL_QUERY_PARAM] === undefined) return;

    const query = { ...route.query };
    delete query[MODAL_QUERY_PARAM];

    await router.replace({ path: route.path, query, hash: route.hash });
  };

  return { openModal, openFromQuery, clearModalQuery, modalRoute };
};
