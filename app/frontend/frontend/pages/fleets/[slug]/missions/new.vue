<script lang="ts">
export default {
  name: "FleetMissionNewPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useMissionDraft } from "@/frontend/composables/useDraftCreate";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();

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

const failed = ref(false);

const start = async () => {
  failed.value = false;
  failed.value = !(await create(props.fleet.slug, { replace: true }));
};

onMounted(() => {
  void start();
});
</script>

<template>
  <!-- A create that failed would otherwise leave nothing on screen but a
       spinner that never stops: this page has no content of its own to fall
       back to, because writing the mission is the whole of its job. -->
  <Empty v-if="failed" :title="t('messages.fleets.mission.create.failure')">
    <template #actions>
      <Btn data-test="mission-create-retry" @click="start">
        {{ t("actions.retry") }}
      </Btn>
      <Btn
        :to="{ name: 'fleet-missions', params: { slug: fleet.slug } }"
        data-test="mission-create-back"
      >
        {{ t("actions.back") }}
      </Btn>
    </template>
  </Empty>
  <Loader v-else :loading="true" />
</template>
