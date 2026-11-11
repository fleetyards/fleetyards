import type { Ref } from "vue";
import type { FleetSquadron } from "@/services/fyApi";

/*
 * Picking a squadron names a team after it, but only over what is empty or
 * still what the previous squadron filled in -- text somebody typed is theirs
 * and stays.
 */
export const useSquadronTakeover =
  (title: Ref<string>, description: Ref<string>) =>
  (squadron: FleetSquadron, previous?: FleetSquadron) => {
    if (!title.value || title.value === previous?.name) {
      title.value = squadron.name;
    }

    if (
      !description.value ||
      description.value === (previous?.shortDescription ?? "")
    ) {
      description.value = squadron.shortDescription ?? "";
    }
  };
