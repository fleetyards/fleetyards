import { type MaybeRef } from "vue";
import { type UserPublic } from "@/services/fyApi";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { useI18n } from "@/shared/composables/useI18n";

export const usePublicHangarMeta = (
  user?: MaybeRef<UserPublic | undefined>,
) => {
  const route = useRoute();

  const { t } = useI18n();

  const { updateMetaInfo } = useMetaInfo({ custom: true });

  const userTitle = computed(() => {
    const username = unref(user)?.username;
    if (!username) return undefined;
    return username[0].toUpperCase() + username.slice(1);
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
  watch(
    () => unref(user),
    () => setTitle(),
  );
};
