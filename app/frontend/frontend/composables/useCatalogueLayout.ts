import {
  type CatalogueList,
  useCatalogueLayoutStore,
} from "@/frontend/stores/catalogueLayout";
import { useComlink } from "@/shared/composables/useComlink";

export const useCatalogueLayout = (list: CatalogueList) => {
  const store = useCatalogueLayoutStore();
  const comlink = useComlink();

  const gridView = computed(() => store.lists[list].gridView);
  const detailsVisible = computed(() => store.lists[list].detailsVisible);

  const openDisplayOptionsModal = () => {
    comlink.emit("open-modal", {
      component: () =>
        import("@/shared/components/DisplayOptionsModal/index.vue"),
      props: {
        gridView: gridView.value,
        testPrefix: list,
        updateCallback: (next: boolean) => {
          store.lists[list].gridView = next;
        },
        detailsVisible: detailsVisible.value,
        updateDetailsCallback: (next: boolean) => {
          store.lists[list].detailsVisible = next;
        },
      },
    });
  };

  return { gridView, detailsVisible, openDisplayOptionsModal };
};
