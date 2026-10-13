import { type MaybeRef } from "vue";
import { type UserPublic } from "@/services/fyApi";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/shared/composables/useI18n";
import { shownName } from "@/frontend/utils/possessiveUsername";

export const usePublicHangarMeta = (
  user?: MaybeRef<UserPublic | undefined>,
) => {
  const route = useRoute();

  const { t } = useI18n();

  const { updateMetaInfo } = useMetaInfo({ custom: true });

  const userTitle = computed(() => {
    const current = unref(user);
    return current?.username ? shownName(current) : undefined;
  });

  const pageTitle = computed(() => {
    if (!userTitle.value) return undefined;
    if (!route.meta.title) return userTitle.value;
    return t(`title.${route.meta.title}`, { user: userTitle.value });
  });

  const setTitle = () => {
    if (!unref(user)) return;

    updateMetaInfo({
      title: pageTitle.value,
    });
  };

  onMounted(() => setTitle());

  watch(
    () => route.name,
    () => setTitle(),
  );
  // A shared plaque names the page while it is open; when it closes and its
  // `plaque` leaves the address, the hangar names itself again.
  watch(
    () => route.query.plaque,
    (plaque) => {
      if (!plaque) setTitle();
    },
  );
  watch(
    () => unref(user),
    () => setTitle(),
  );
};
