<script lang="ts">
export default {
  name: "OauthApplicationActionItems",
};
</script>

<script lang="ts" setup>
import {
  type OauthApplication,
  useDestroyOauthApplication,
  getOauthApplicationsQueryKey,
} from "@/services/fyAdminApi";
import { useQueryClient } from "@tanstack/vue-query";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";

type Props = {
  oauthApplication: OauthApplication;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm } = useAppNotifications();
const { extend } = useBreadCrumbs();

const queryClient = useQueryClient();

const destroyMutation = useDestroyOauthApplication();

const destroy = () => {
  displayConfirm({
    text: t("messages.confirm.oauthApplication.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.oauthApplication.id });
      void queryClient.invalidateQueries({
        queryKey: getOauthApplicationsQueryKey(),
      });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.edit')"
    :size="BtnSizesEnum.SMALL"
    :to="
      extend({
        name: 'admin-oauth-application-edit',
        params: { id: props.oauthApplication.id },
      })
    "
  >
    <i class="fad fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    :size="BtnSizesEnum.SMALL"
    :variant="BtnVariantsEnum.DANGER"
    @click="destroy"
  >
    <i class="fad fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
