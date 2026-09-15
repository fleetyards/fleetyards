<script lang="ts">
export default {
  name: "FleetEventNewPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
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

const { t } = useI18n();

const failed = ref(false);

const start = async () => {
  failed.value = false;
  failed.value = !(await create(props.fleet.slug, {
    startsAt: route.query.startsAt as string | undefined,
    missionSlug: route.query.mission as string | undefined,
    replace: true,
  }));
};

onMounted(() => {
  void start();
});
</script>

<template>
  <!-- A create that failed would otherwise leave nothing on screen but a
       spinner that never stops: this page has no content of its own to fall
       back to, because writing the event is the whole of its job. -->
  <Empty v-if="failed" :title="t('messages.fleets.event.create.failure')">
    <template #actions>
      <Btn data-test="event-create-retry" @click="start">
        {{ t("actions.retry") }}
      </Btn>
      <Btn
        :to="{ name: 'fleet-events', params: { slug: fleet.slug } }"
        data-test="event-create-back"
      >
        {{ t("actions.back") }}
      </Btn>
    </template>
  </Empty>
  <Loader v-else :loading="true" />
</template>
