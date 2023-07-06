<template>
  <div class="fade-list-item col-12 flex-list-heading">
    <div class="flex-list-row">
      <div class="username">
        <router-link :to="sort('user_username')">
          {{ t("labels.username") }}
        </router-link>
      </div>
      <div class="rsi-handle">
        <router-link :to="sort('user_rsi_handle')">
          {{ t("labels.user.rsiHandle") }}
        </router-link>
      </div>
      <div class="role" />
      <div class="joined">
        {{ t("labels.fleet.members.invited") }} /
        {{ t("labels.fleet.members.joined") }}
      </div>
      <div class="links" />
      <div v-if="actionsVisible" class="actions actions-3x">
        {{ t("labels.actions") }}
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { sortByToggle } from "@/frontend/utils/Sorting";
import { useRoute } from "vue-router/composables";
import { useI18n } from "@/frontend/composables/useI18n";
import type { FleetYardsLocation } from "@/frontend/utils/Sorting";

type Props = {
  actionsVisible: boolean;
};

withDefaults(defineProps<Props>(), {
  actionsVisible: false,
});

const { t } = useI18n();

const route = useRoute();

const sort = (field: string) =>
  sortByToggle(route as unknown as FleetYardsLocation, field);
</script>

<script lang="ts">
export default {
  name: "MembersListHead",
};
</script>
