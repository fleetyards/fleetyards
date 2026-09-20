import type { MaybeRefOrGetter } from "vue";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";
import type { RelationshipRow } from "@/frontend/components/Relationships/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Friendship,
  type RelationshipStateEnum,
  useAcceptFriendship,
  useCreateFriendship,
  useDeclineFriendship,
  useDestroyFriendship,
  useFriends,
  useIgnoreFriendship,
} from "@/services/fyApi";

// The friends list and everything you can do to a row.
//
// Rows are normalised into `RelationshipRow` so the table can be shared with
// fleet alliances: the only difference between the two is that one names a
// person and the other an organisation.
export const useFriendships = (
  state: MaybeRefOrGetter<RelationshipStateEnum>,
  direction: MaybeRefOrGetter<"incoming" | "outgoing" | undefined>,
) => {
  const { t } = useI18n();
  const { displayAlert, displaySuccess } = useAppNotifications();

  const params = computed(() => ({
    state: toValue(state),
    direction: toValue(direction),
  }));

  const query = useFriends(params);

  const rows = computed<RelationshipRow[]>(() =>
    (query.data.value?.items ?? []).map((friendship: Friendship) => ({
      id: friendship.id,
      handle: friendship.user.username,
      label: friendship.user.username,
      avatar: friendship.user.avatar,
      userId: friendship.user.id,
      online: friendship.user.online,
      lastActiveAt: friendship.user.lastActiveAt,
      state: friendship.state,
      direction: friendship.direction,
      createdAt: friendship.createdAt,
    })),
  );

  const asyncStatus: AsyncStatus = {
    fetchStatus: computed(() => query.fetchStatus.value),
    isError: computed(() => query.isError.value),
    isPending: computed(() => query.isPending.value),
    isLoading: computed(() => query.isLoading.value),
    isFetching: computed(() => query.isFetching.value),
    isRefetching: computed(() => query.isRefetching.value),
    error: computed(() => query.error.value),
  };

  const mutations = {
    create: useCreateFriendship(),
    accept: useAcceptFriendship(),
    decline: useDeclineFriendship(),
    ignore: useIgnoreFriendship(),
    destroy: useDestroyFriendship(),
  };

  const busy = ref(false);

  const run = async (action: () => Promise<unknown>, successKey: string) => {
    busy.value = true;

    try {
      await action();
      await query.refetch();
      displaySuccess({ text: t(`messages.friends.${successKey}.success`) });

      return true;
    } catch {
      displayAlert({ text: t(`messages.friends.${successKey}.failure`) });

      return false;
    } finally {
      busy.value = false;
    }
  };

  return {
    rows,
    asyncStatus,
    busy,
    isLoading: query.isLoading,
    refetch: query.refetch,

    onAdd: (username: string) =>
      run(
        () => mutations.create.mutateAsync({ data: { username } }),
        "request",
      ),
    onAccept: (row: RelationshipRow) =>
      run(
        () => mutations.accept.mutateAsync({ username: row.handle }),
        "accept",
      ),
    onDecline: (row: RelationshipRow) =>
      run(
        () => mutations.decline.mutateAsync({ username: row.handle }),
        "decline",
      ),
    onIgnore: (row: RelationshipRow) =>
      run(
        () => mutations.ignore.mutateAsync({ username: row.handle }),
        "ignore",
      ),
    onRemove: (row: RelationshipRow) =>
      run(
        () => mutations.destroy.mutateAsync({ username: row.handle }),
        "remove",
      ),
  };
};
