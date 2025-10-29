<script lang="ts">
export default {
  name: "InviteUrlModal",
};
</script>

<script lang="ts" setup>
import copyText from "@/frontend/utils/CopyText";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useFleetInviteUrls as useFleetInviteUrlsQuery,
  useCreateFleetInviteUrl as useCreateFleetInviteUrlMutation,
  useDestroyFleetInviteUrl as useDestroyFleetInviteUrlMutation,
} from "@/services/fyApi";

import {
  Fleet,
  FleetInviteUrl,
  FleetInviteUrlCreateInput,
} from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess, displayAlert } = useAppNotifications();

const form = ref<FleetInviteUrlCreateInput>({});

const expiresAfterOptions = [
  {
    label: t("labels.fleet.inviteUrls.expiresAfterOptions.infinite"),
    value: null,
  },
  {
    label: t("labels.fleet.inviteUrls.expiresAfterOptions.30_minutes"),
    value: 30,
  },
  {
    label: t("labels.fleet.inviteUrls.expiresAfterOptions.1_hour"),
    value: 60,
  },
  {
    label: t("labels.fleet.inviteUrls.expiresAfterOptions.6_hours"),
    value: 6 * 60,
  },
  {
    label: t("labels.fleet.inviteUrls.expiresAfterOptions.12_hours"),
    value: 12 * 60,
  },
  {
    label: t("labels.fleet.inviteUrls.expiresAfterOptions.1_day"),
    value: 24 * 60,
  },
  {
    label: t("labels.fleet.inviteUrls.expiresAfterOptions.7_days"),
    value: 24 * 60 * 7,
  },
];

const limitOptions = [
  {
    label: t("labels.fleet.inviteUrls.limitOptions.infinite"),
    value: null,
  },
  {
    label: t("labels.fleet.inviteUrls.limitOptions.1"),
    value: 1,
  },
  {
    label: t("labels.fleet.inviteUrls.limitOptions.5"),
    value: 5,
  },
  {
    label: t("labels.fleet.inviteUrls.limitOptions.10"),
    value: 10,
  },
  {
    label: t("labels.fleet.inviteUrls.limitOptions.25"),
    value: 25,
  },
  {
    label: t("labels.fleet.inviteUrls.limitOptions.50"),
    value: 50,
  },
  {
    label: t("labels.fleet.inviteUrls.limitOptions.100"),
    value: 100,
  },
];

onMounted(() => {
  setupForm();
});

const setupForm = () => {
  form.value = {
    expiresAfterMinutes: undefined,
    limit: undefined,
  };
};

const { data: inviteUrls, refetch } = useFleetInviteUrlsQuery(props.fleet.slug);

const createMutation = useCreateFleetInviteUrlMutation();

const create = async () => {
  await createMutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      data: form.value,
    })
    .then(() => {
      refetch();
    })
    .catch((error) => {
      console.error(error);
    });
};

const destroyMutation = useDestroyFleetInviteUrlMutation();

const remove = async (inviteUrl: FleetInviteUrl) => {
  await destroyMutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      token: inviteUrl.token,
    })
    .then(() => {
      refetch();
    })
    .catch((error) => {
      console.error(error);
    });
};

const usesLeft = (inviteUrl: FleetInviteUrl) => {
  if (!inviteUrl.limit && inviteUrl.limit !== 0) {
    return t("labels.fleet.inviteUrls.noLimit");
  }

  return t("labels.fleet.inviteUrls.usesLeft", {
    count: inviteUrl.limit,
  });
};

const copy = (inviteUrl: FleetInviteUrl) => {
  copyText(inviteUrl.url).then(
    () => {
      displaySuccess({
        text: t("messages.copyInviteUrl.success", {
          url: inviteUrl.url,
        }),
      });
    },
    () => {
      displayAlert({
        text: t("messages.copyInviteUrl.failure"),
      });
    },
  );
};
</script>

<template>
  <Modal v-if="fleet" :title="t('headlines.fleets.inviteUrls')">
    <div
      v-for="inviteUrl in inviteUrls"
      :key="inviteUrl.token"
      class="invite-url"
    >
      <div class="invite-url-main">
        <FormInput
          :id="inviteUrl.token"
          v-model="inviteUrl.url"
          name="token"
          :disabled="true"
          :no-label="true"
          :inline="true"
          class="url-input"
          @click="copy(inviteUrl)"
        />
        <Btn :size="BtnSizesEnum.SMALL" :inline="true" @click="copy(inviteUrl)">
          <i class="fad fa-copy" />
        </Btn>
        <Btn
          :size="BtnSizesEnum.SMALL"
          :inline="true"
          @click="remove(inviteUrl)"
        >
          <i class="fad fa-trash" />
        </Btn>
      </div>
      <div class="invite-url-subline">
        <div v-if="inviteUrl.expired">
          {{ t("labels.fleet.inviteUrls.expired") }}
        </div>
        <div v-else-if="inviteUrl.expiresAfterLabel">
          {{
            t("labels.fleet.inviteUrls.expiresIn", {
              time: inviteUrl.expiresAfterLabel,
            })
          }}
        </div>
        <div v-else>
          {{ t("labels.fleet.inviteUrls.noExpiration") }}
        </div>
        <div>{{ usesLeft(inviteUrl) }}</div>
      </div>
    </div>

    <template v-if="form">
      <hr />
      <FilterGroup
        v-model="form.expiresAfterMinutes"
        :options="expiresAfterOptions"
        :label="t('labels.filters.fleets.inviteUrls.expiresAfter')"
        name="expires-after"
      />
      <FilterGroup
        v-model="form.limit"
        :options="limitOptions"
        :label="t('labels.filters.fleets.inviteUrls.limit')"
        name="limit"
      />
      <Btn @click="create">
        {{ t("actions.fleet.inviteUrls.create") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
