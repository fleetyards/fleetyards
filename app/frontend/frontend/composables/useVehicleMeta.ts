import { type MaybeRefOrGetter } from "vue";
import { type Vehicle } from "@/services/fyApi";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/shared/composables/useI18n";

const DESCRIPTION_LENGTH = 200;

// A ship's pages name the ship and the open tab, and describe it the way the
// server does for a link to them: its dedication, else its model.
export const useVehicleMeta = (
  vehicle: MaybeRefOrGetter<Vehicle | undefined>,
) => {
  const route = useRoute();
  const { t } = useI18n();
  const { updateMetaInfo } = useMetaInfo({ custom: true });

  const update = () => {
    const current = toValue(vehicle);
    if (!current) {
      return;
    }

    const name = current.name || current.model.name;
    const tab = route.meta.title ? t(`title.${route.meta.title}`) : undefined;
    const text = current.dedication || current.model.description || "";
    const picture =
      current.image || current.modelImage || current.model.media.storeImage;

    updateMetaInfo({
      title: tab ? `${name} · ${tab}` : name,
      description: text
        ? text.replace(/<[^>]*>/g, "").slice(0, DESCRIPTION_LENGTH)
        : undefined,
      image: picture?.largeUrl || picture?.url,
      type: "article",
    });
  };

  watch(() => toValue(vehicle), update, { immediate: true });
  watch(() => route.name, update);
};
