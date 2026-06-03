<script lang="ts" setup>
import { useUser as useUserQuery } from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import TabNavView from "@/shared/components/TabNavView/index.vue";
import { routes as userChildRoutes } from "./[id]/routes";
import { useI18n } from "@/shared/composables/useI18n";

const route = useRoute();
const { t } = useI18n();

const { data: user, ...asyncStatus } = useUserQuery(route.params.id as string);

const crumbs = computed(() => [
  {
    to: { name: "admin-users", hash: user.value ? `#${user.value.id}` : "" },
    label: t("nav.admin.users.index"),
  },
  {
    to: {
      name: "admin-user-edit",
      params: { id: route.params.id },
    },
    label: user.value?.username || "",
  },
]);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" />

      <TabNavView :routes="userChildRoutes" authenticated>
        <template #content>
          <router-view :user="user" />
        </template>
      </TabNavView>
    </template>
  </AsyncData>
</template>
