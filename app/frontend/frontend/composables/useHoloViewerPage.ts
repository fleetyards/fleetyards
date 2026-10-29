import { type AppModalOptions } from "@/shared/components/AppModal/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { type RouteLocationNamedRaw } from "vue-router";

type Options = {
  title: () => string | undefined;
  // The modal to open, or nothing when there is no holo to show.
  modal: () => AppModalOptions | undefined;
  backRoute: () => RouteLocationNamedRaw;
};

// A full screen holo viewer as a page of its own: the page is empty behind
// its modal, so however the modal closes -- the close button, Escape, the
// backdrop -- it goes back to the page it came from, with the textured holo
// and paint it was left on.
export const useHoloViewerPage = ({ title, modal, backRoute }: Options) => {
  const route = useRoute();

  const router = useRouter();

  const comlink = useComlink();

  const { updateMetaInfo } = useMetaInfo();

  const viewerRoute = route.name;

  let unsubscribe: (() => void) | undefined;

  onMounted(() => {
    const options = modal();

    if (!options) {
      void router.replace(backRoute());
      return;
    }

    updateMetaInfo({ title: title() });

    unsubscribe = comlink.on("modal-closed", () => {
      if (route.name !== viewerRoute) return;

      const { textured, paint } = route.query;

      void router.replace({
        ...backRoute(),
        query: textured ? { textured, paint } : undefined,
      });
    });

    comlink.emit("open-modal", options);
  });

  onUnmounted(() => {
    unsubscribe?.();
  });
};
