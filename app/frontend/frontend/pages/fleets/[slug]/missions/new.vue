<script lang="ts">
export default {
  name: "FleetMissionNewPage",
};
</script>

<script lang="ts" setup>
import Loader from "@/shared/components/Loader/index.vue";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { useMissionDraft } from "@/frontend/composables/useDraftCreate";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

/*
 * No form of its own any more. A mission has to exist before its teams, ships
 * and slots can hang off it, so the list writes one and hands the author to the
 * editor -- and this path, which people have bookmarked and which other pages
 * still link to, does the same rather than offering a second way to create.
 *
 * `replace`, so Back returns to wherever they came from instead of landing here
 * and writing another draft.
 */
const { create } = useMissionDraft();

onMounted(() => {
  void create(props.fleet.slug, { replace: true });
});
</script>

<template>
  <Loader :loading="true" />
</template>
