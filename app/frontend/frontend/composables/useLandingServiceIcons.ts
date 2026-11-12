import { type LandingServiceEnum, useLandingServices } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import {
  LANDING_SERVICE_ORDER,
  type LandingServiceIcon,
  landingServiceLabel,
} from "@/shared/utils/LandingServices";

// The game's icon for each service, fetched once: four rows that only change
// with an export.
export const useLandingServiceIcons = () => {
  const { t } = useI18n();

  const { data } = useLandingServices({
    query: { staleTime: Infinity, gcTime: Infinity },
  });

  const urls = computed(
    () =>
      new Map(
        (data.value ?? []).map((service) => [service.key, service.icon?.url]),
      ),
  );

  const iconsFor = (
    services?: LandingServiceEnum[] | null,
  ): LandingServiceIcon[] =>
    LANDING_SERVICE_ORDER.filter((key) => services?.includes(key)).map(
      (key) => ({
        key,
        label: landingServiceLabel(key, t),
        url: urls.value.get(key),
      }),
    );

  const options = computed(() =>
    iconsFor(LANDING_SERVICE_ORDER).map((service) => ({
      value: service.key,
      label: service.label,
      icon: service.url,
    })),
  );

  return { iconsFor, options };
};
