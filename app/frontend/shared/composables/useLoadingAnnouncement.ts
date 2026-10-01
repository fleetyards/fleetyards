import { useI18n } from "@/shared/composables/useI18n";

// A live region only announces a change to text that was already in the
// document, and loading indicators often mount already loading - an expanded
// row, a step that appears once it starts. So the text always arrives a moment
// after the region does, which screen readers pick up whichever way the
// indicator appeared.
const ANNOUNCE_DELAY = 150;

export const useLoadingAnnouncement = (
  loading: MaybeRefOrGetter<boolean>,
  label: MaybeRefOrGetter<string | undefined>,
) => {
  const { t } = useI18n();

  const statusText = ref("");

  let announceTimer: ReturnType<typeof setTimeout> | undefined;

  const clearAnnounce = () => {
    if (announceTimer) clearTimeout(announceTimer);
    announceTimer = undefined;
  };

  watch(
    () => [toValue(loading), toValue(label)] as const,
    ([isLoading, text]) => {
      clearAnnounce();

      if (!isLoading) {
        statusText.value = "";
        return;
      }

      announceTimer = setTimeout(() => {
        statusText.value = text || t("labels.loading");
      }, ANNOUNCE_DELAY);
    },
    { immediate: true },
  );

  onBeforeUnmount(clearAnnounce);

  return statusText;
};
