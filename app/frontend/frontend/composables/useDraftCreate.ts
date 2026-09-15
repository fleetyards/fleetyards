import {
  FleetEventVisibilityEnum,
  useCreateFleetEvent,
  useCreateFleetMission,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

/*
 * Writing a mission or an event and going straight to its editor. Shared rather
 * than repeated, because four places start this now -- the two list pages and
 * the two paths that used to open a create form -- and they have to agree on
 * what a new one looks like and where it lands.
 *
 * Nothing here is offered to the fleet: both arrive as drafts, which only their
 * author and whoever could publish them can see, and deleting one removes it.
 */

// An event's own timezone, read once. A create that omitted it would be refused,
// and the editor is where the author changes it.
const browserTimezone = () => {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
  } catch {
    return "UTC";
  }
};

export const useMissionDraft = () => {
  const { t } = useI18n();
  const { displayAlert } = useAppNotifications();
  const router = useRouter();
  const mutation = useCreateFleetMission();

  const create = async (fleetSlug: string, { replace = false } = {}) => {
    try {
      const mission = await mutation.mutateAsync({
        fleetSlug,
        data: { title: t("labels.fleets.missions.untitled") },
      });

      if (!mission?.slug) return;

      const to = {
        name: "fleet-mission-edit",
        params: { slug: fleetSlug, mission: mission.slug },
      };

      // `replace` for a page that only exists to do this: the create URL must
      // not sit in the history for Back to land on and write a second draft.
      await (replace ? router.replace(to) : router.push(to));
    } catch {
      displayAlert({ text: t("messages.fleets.mission.create.failure") });
    }
  };

  return { create, pending: mutation.isPending };
};

export const useEventDraft = () => {
  const { t } = useI18n();
  const { displayAlert } = useAppNotifications();
  const router = useRouter();
  const mutation = useCreateFleetEvent();

  const create = async (
    fleetSlug: string,
    {
      startsAt,
      missionSlug,
      replace = false,
    }: {
      startsAt?: Date | string;
      missionSlug?: string;
      replace?: boolean;
    } = {},
  ) => {
    const startsAtIso =
      startsAt instanceof Date
        ? startsAt.toISOString()
        : (startsAt ?? new Date().toISOString());

    try {
      const event = await mutation.mutateAsync({
        fleetSlug,
        data: {
          title: t("labels.fleets.events.untitled"),
          startsAt: startsAtIso,
          timezone: browserTimezone(),
          visibility: FleetEventVisibilityEnum.MEMBERS,
          // The API copies the mission's teams onto the event when this is
          // given, which is the whole point of spawning one from a mission.
          ...(missionSlug ? { missionSlug } : {}),
        },
      });

      if (!event?.slug) return;

      const to = {
        name: "fleet-event-edit",
        params: { slug: fleetSlug, event: event.slug },
      };

      await (replace ? router.replace(to) : router.push(to));
    } catch {
      displayAlert({ text: t("messages.fleets.event.create.failure") });
    }
  };

  return { create, pending: mutation.isPending };
};
