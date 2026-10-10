import { useEventDraft } from "@/frontend/composables/useDraftCreate";
import { useComlink } from "@/shared/composables/useComlink";
import type { Fleet, Mission } from "@/services/fyApi";

/*
 * Planning an event from a button: a mission template first, because the API
 * copies a mission's teams only while it writes the event -- the editor cannot
 * apply one later. Whoever cannot read the fleet's missions has none to pick
 * from, and goes straight to a blank draft.
 */
export const useEventPlanner = () => {
  const comlink = useComlink();
  const { create, pending } = useEventDraft();

  const plan = (
    fleet: Fleet,
    { startsAt, withTemplate }: { startsAt?: Date; withTemplate: boolean },
  ) => {
    if (!withTemplate) {
      void create(fleet.slug, { startsAt });
      return;
    }

    // A pick made while the last draft is still being written would be dropped.
    if (pending.value) return;

    comlink.emit("open-modal", {
      component: () =>
        import("@/frontend/components/Fleets/Events/MissionTemplatePicker/index.vue"),
      props: {
        fleet,
        onPick: (mission: Mission | null) => {
          void create(fleet.slug, { startsAt, missionSlug: mission?.slug });
        },
      },
    });
  };

  return { plan, pending };
};
