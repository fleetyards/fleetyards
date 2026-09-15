<script lang="ts">
export default {
  name: "FleetEventNewPage",
};
</script>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { useEventDraft } from "@/frontend/composables/useDraftCreate";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const route = useRoute();

/*
 * No form of its own any more. An event has to exist before its teams, ships and
 * slots can hang off it, so the list writes one and hands the author to the
 * editor -- and this path, which people have bookmarked and which the "spawn an
 * event from this mission" action still uses, does the same.
 *
 * Both of the things it was called with still carry: the day clicked on the
 * calendar, and the mission to build it from. The API copies that mission's
 * teams onto the event, which the old form only prefilled on the client.
 *
 * `replace`, so Back returns to wherever they came from instead of landing here
 * and writing another draft.
 */
const { create } = useEventDraft();

onMounted(() => {
  void create(props.fleet.slug, {
    startsAt: route.query.startsAt as string | undefined,
    missionSlug: route.query.mission as string | undefined,
    replace: true,
  });
});
</script>

<template>
  <Loader :loading="true" />
</template>
