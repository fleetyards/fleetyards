import { type MaybeRef } from "vue";
import { type Fleet } from "@/services/fyApi";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/shared/composables/useI18n";

export const useFleetMeta = (fleet?: MaybeRef<Fleet | undefined>) => {
  const route = useRoute();

  const { t } = useI18n();

  const { updateMetaInfo } = useMetaInfo({ custom: true });

  const fleetTitle = computed(() => {
    if (!unref(fleet)) {
      return undefined;
    }

    if (!route.meta.title) {
      return unref(fleet)?.name;
    }

    return t(`title.${route.meta.title}`, { fleet: unref(fleet)?.name });
  });

  onMounted(() => {
    setTitle();
  });

  const setTitle = () => {
    if (!unref(fleet)) {
      return;
    }

    updateMetaInfo({
      title: fleetTitle.value,
      description: unref(fleet)?.description,
      image: unref(fleet)?.logo,
      type: "article",
    });
  };

  watch(
    () => route.name,
    () => {
      setTitle();
    },
  );

  watch(
    () => unref(fleet),
    () => {
      setTitle();
    },
  );
};
