import type { MaybeRefOrGetter } from "vue";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";
import type { RelationshipRow } from "@/frontend/components/Relationships/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type FleetAlliance,
  type RelationshipStateEnum,
  useAcceptFleetAlliance,
  useCreateFleetAlliance,
  useDeclineFleetAlliance,
  useDestroyFleetAlliance,
  useFleetAllies,
  useIgnoreFleetAlliance,
} from "@/services/fyApi";

// The same list and the same five actions as `useFriendships`, done for a fleet
// rather than for a person. Kept apart rather than made generic: every call
// takes the acting fleet's slug in the path, which is not a difference a type
// parameter can carry.
export const useFleetAlliances = (
  fleetSlug: MaybeRefOrGetter<string>,
  state: MaybeRefOrGetter<RelationshipStateEnum>,
  direction: MaybeRefOrGetter<"incoming" | "outgoing" | undefined>,
) => {
  const { t } = useI18n();
  const { displayAlert, displaySuccess } = useAppNotifications();

  const slug = computed(() => toValue(fleetSlug));

  const params = computed(() => ({
    state: toValue(state),
    direction: toValue(direction),
  }));

  const query = useFleetAllies(slug, params, {
    query: { enabled: computed(() => !!slug.value) },
  });

  const rows = computed<RelationshipRow[]>(() =>
    (query.data.value?.items ?? []).map((alliance: FleetAlliance) => ({
      id: alliance.id,
      handle: alliance.fleet.slug,
      label: alliance.fleet.name,
      avatar: alliance.fleet.logo,
      state: alliance.state,
      direction: alliance.direction,
      createdAt: alliance.createdAt,
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
    create: useCreateFleetAlliance(),
    accept: useAcceptFleetAlliance(),
    decline: useDeclineFleetAlliance(),
    ignore: useIgnoreFleetAlliance(),
    destroy: useDestroyFleetAlliance(),
  };

  const busy = ref(false);

  const run = async (action: () => Promise<unknown>, successKey: string) => {
    busy.value = true;

    try {
      await action();
      await query.refetch();
      displaySuccess({ text: t(`messages.fleetAllies.${successKey}.success`) });

      return true;
    } catch {
      displayAlert({ text: t(`messages.fleetAllies.${successKey}.failure`) });

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

    onAdd: (allySlug: string) =>
      run(
        () =>
          mutations.create.mutateAsync({
            fleetSlug: slug.value,
            data: { slug: allySlug },
          }),
        "request",
      ),
    onAccept: (row: RelationshipRow) =>
      run(
        () =>
          mutations.accept.mutateAsync({
            fleetSlug: slug.value,
            allySlug: row.handle,
          }),
        "accept",
      ),
    onDecline: (row: RelationshipRow) =>
      run(
        () =>
          mutations.decline.mutateAsync({
            fleetSlug: slug.value,
            allySlug: row.handle,
          }),
        "decline",
      ),
    onIgnore: (row: RelationshipRow) =>
      run(
        () =>
          mutations.ignore.mutateAsync({
            fleetSlug: slug.value,
            allySlug: row.handle,
          }),
        "ignore",
      ),
    onRemove: (row: RelationshipRow) =>
      run(
        () =>
          mutations.destroy.mutateAsync({
            fleetSlug: slug.value,
            allySlug: row.handle,
          }),
        "remove",
      ),
  };
};
