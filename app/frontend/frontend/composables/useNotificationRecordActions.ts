import {
  acceptFleetMember,
  acceptFleetMembership,
  declineFleetMember,
  declineFleetMembership,
  FleetEventSignupStatusEnum,
  FleetMembershipStatusEnum,
  NotificationTypeEnum,
  signupFleetEvent,
  syncRsiHangar,
  updateVehicle,
  useFleetEvent,
  useFleetMember,
  useFleetMembership,
  useShowVehicle,
  useSyncRsiHangarStatus,
  type Notification,
} from "@/services/fyApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";

export type NotificationAction = {
  key: string;
  icon: string;
  tone?: `${BtnTonesEnum}`;
  run: () => Promise<unknown>;
};

/*
 * Which record a notification's actions depend on. A type that is not in here
 * has nothing to do beyond its link - most notifications report something that
 * has already happened.
 */
const LOOKUPS = {
  fleet_invite: "ownMembership",
  fleet_member_requested: "member",
  fleet_event_published: "event",
  fleet_event_starting_soon: "event",
  fleet_event_signup_confirmed: "event",
  fleet_event_signup_assigned: "event",
  hangar_sync_finished: "sync",
  hangar_sync_failed: "sync",
  model_on_sale: "vehicle",
} as const satisfies Partial<Record<`${NotificationTypeEnum}`, string>>;

type Lookup = (typeof LOOKUPS)[keyof typeof LOOKUPS];

const lookupFor = (notification?: Notification): Lookup | undefined =>
  notification
    ? LOOKUPS[notification.notificationType as keyof typeof LOOKUPS]
    : undefined;

/*
 * The actions a notification can still offer, decided by the record as it is
 * now rather than as it was when the notification was written. An invite
 * answered on the fleet page half an hour ago leaves nothing here, which is
 * the point: a button that would only produce a 422 is worse than no button.
 */
export const useNotificationRecordActions = (
  notification: Ref<Notification | undefined>,
) => {
  const record = computed(() => notification.value?.record);
  const lookup = computed(() => lookupFor(notification.value));

  const fleetSlug = computed(() => record.value?.fleetSlug || "");
  const username = computed(() => record.value?.username || "");
  const eventSlug = computed(() => record.value?.eventSlug || "");
  const recordId = computed(() => record.value?.id || "");

  // A query cannot be created conditionally, so all five exist and only the
  // one the notification calls for is ever enabled.
  const enabledFor = (kind: Lookup, ...required: Ref<string>[]) =>
    computed(
      () => lookup.value === kind && required.every((value) => !!value.value),
    );

  const queries = {
    ownMembership: useFleetMembership(fleetSlug, {
      query: { enabled: enabledFor("ownMembership", fleetSlug), retry: false },
    }),
    member: useFleetMember(fleetSlug, username, {
      query: {
        enabled: enabledFor("member", fleetSlug, username),
        retry: false,
      },
    }),
    event: useFleetEvent(fleetSlug, eventSlug, undefined, {
      query: {
        enabled: enabledFor("event", fleetSlug, eventSlug),
        retry: false,
      },
    }),
    vehicle: useShowVehicle(recordId, {
      query: { enabled: enabledFor("vehicle", recordId), retry: false },
    }),
    sync: useSyncRsiHangarStatus({
      query: { enabled: computed(() => lookup.value === "sync"), retry: false },
    }),
  };

  const active = computed(() =>
    lookup.value ? queries[lookup.value] : undefined,
  );

  const isLoading = computed(() => !!active.value?.isLoading.value);

  // The record is gone, or was never the reader's to see. Nothing to act on,
  // and saying so beats a row of buttons that cannot work.
  const isUnavailable = computed(() => !!active.value?.isError.value);

  const refresh = async () => {
    await active.value?.refetch();
  };

  const membershipActions = (
    status: FleetMembershipStatusEnum | undefined,
    expected: FleetMembershipStatusEnum,
    accept: () => Promise<unknown>,
    decline: () => Promise<unknown>,
  ): NotificationAction[] => {
    if (status !== expected) {
      return [];
    }

    return [
      { key: "accept", icon: "fa-duotone fa-check", run: accept },
      {
        key: "decline",
        icon: "fa-duotone fa-xmark",
        tone: BtnTonesEnum.DANGER,
        run: decline,
      },
    ];
  };

  const actions = computed<NotificationAction[]>(() => {
    switch (notification.value?.notificationType) {
      case NotificationTypeEnum.FLEET_INVITE:
        return membershipActions(
          queries.ownMembership.data.value?.status,
          FleetMembershipStatusEnum.INVITED,
          () => acceptFleetMembership(fleetSlug.value),
          () => declineFleetMembership(fleetSlug.value),
        );

      case NotificationTypeEnum.FLEET_MEMBER_REQUESTED:
        return membershipActions(
          queries.member.data.value?.status,
          FleetMembershipStatusEnum.REQUESTED,
          () => acceptFleetMember(fleetSlug.value, username.value),
          () => declineFleetMember(fleetSlug.value, username.value),
        );

      case NotificationTypeEnum.FLEET_EVENT_PUBLISHED:
      case NotificationTypeEnum.FLEET_EVENT_STARTING_SOON: {
        const event = queries.event.data.value;

        if (!event?.signupsOpen || event.past) {
          return [];
        }

        // Only the plain yes. The event page carries the three-way status and
        // the ship picker; repeating them here would be a form, not a call to
        // action.
        return [
          {
            key: "signUp",
            icon: "fa-duotone fa-check",
            run: () =>
              signupFleetEvent(fleetSlug.value, eventSlug.value, {
                status: FleetEventSignupStatusEnum.CONFIRMED,
              }),
          },
        ];
      }

      case NotificationTypeEnum.FLEET_EVENT_SIGNUP_CONFIRMED:
      case NotificationTypeEnum.FLEET_EVENT_SIGNUP_ASSIGNED: {
        const event = queries.event.data.value;

        if (!event || event.past) {
          return [];
        }

        return [
          {
            key: "withdraw",
            icon: "fa-duotone fa-arrow-right-from-bracket",
            tone: BtnTonesEnum.DANGER,
            run: () =>
              signupFleetEvent(fleetSlug.value, eventSlug.value, {
                status: FleetEventSignupStatusEnum.WITHDRAWN,
              }),
          },
        ];
      }

      case NotificationTypeEnum.HANGAR_SYNC_FINISHED:
      case NotificationTypeEnum.HANGAR_SYNC_FAILED: {
        if (queries.sync.data.value?.active !== false) {
          return [];
        }

        return [
          {
            key: "syncAgain",
            icon: "fa-duotone fa-rotate",
            run: () => syncRsiHangar({}),
          },
        ];
      }

      case NotificationTypeEnum.MODEL_ON_SALE: {
        const vehicle = queries.vehicle.data.value;

        if (!vehicle?.wanted) {
          return [];
        }

        return [
          {
            key: "markAsBought",
            icon: "fa-duotone fa-cart-shopping",
            run: () => updateVehicle(vehicle.id, { wanted: false }),
          },
        ];
      }

      default:
        return [];
    }
  });

  // The pledge store sits behind the ship, so it only becomes offerable once
  // the vehicle has been loaded.
  const externalLink = computed(() => {
    if (
      notification.value?.notificationType !==
      NotificationTypeEnum.MODEL_ON_SALE
    ) {
      return undefined;
    }

    const storeUrl = queries.vehicle.data.value?.model?.links?.storeUrl;

    return storeUrl
      ? { key: "openStore", icon: "fa-duotone fa-store", href: storeUrl }
      : undefined;
  });

  return { actions, externalLink, isLoading, isUnavailable, refresh };
};
