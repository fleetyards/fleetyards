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
          :disabled="true"
          :no-label="true"
          :inline="true"
          class="url-input"
          @click="copy(inviteUrl)"
        />
        <Btn size="small" :inline="true" @click="copy(inviteUrl)">
          <i class="fad fa-copy" />
        </Btn>
        <Btn size="small" :inline="true" @click="remove(inviteUrl)">
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

<script lang="ts" setup>
import copyText from "@/frontend/utils/CopyText";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";

import {
  Fleet,
  FleetInviteUrl,
  FleetInviteUrlCreateInput,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty();

const { fleetInviteUrls: fleetInviteUrlsService } = useApiClient();

const form = ref<FleetInviteUrlCreateInput>({});

const expiresAfterOptions = [
  {
    name: t("labels.fleet.inviteUrls.expiresAfterOptions.infinite"),
    value: null,
  },
  {
    name: t("labels.fleet.inviteUrls.expiresAfterOptions.30_minutes"),
    value: 30,
  },
  {
    name: t("labels.fleet.inviteUrls.expiresAfterOptions.1_hour"),
    value: 60,
  },
  {
    name: t("labels.fleet.inviteUrls.expiresAfterOptions.6_hours"),
    value: 6 * 60,
  },
  {
    name: t("labels.fleet.inviteUrls.expiresAfterOptions.12_hours"),
    value: 12 * 60,
  },
  {
    name: t("labels.fleet.inviteUrls.expiresAfterOptions.1_day"),
    value: 24 * 60,
  },
  {
    name: t("labels.fleet.inviteUrls.expiresAfterOptions.7_days"),
    value: 24 * 60 * 7,
  },
];

const limitOptions = [
  {
    name: t("labels.fleet.inviteUrls.limitOptions.infinite"),
    value: null,
  },
  {
    name: t("labels.fleet.inviteUrls.limitOptions.1"),
    value: 1,
  },
  {
    name: t("labels.fleet.inviteUrls.limitOptions.5"),
    value: 5,
  },
  {
    name: t("labels.fleet.inviteUrls.limitOptions.10"),
    value: 10,
  },
  {
    name: t("labels.fleet.inviteUrls.limitOptions.25"),
    value: 25,
  },
  {
    name: t("labels.fleet.inviteUrls.limitOptions.50"),
    value: 50,
  },
  {
    name: t("labels.fleet.inviteUrls.limitOptions.100"),
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

const { data: inviteUrls, refetch } = useQuery({
  queryKey: ["fleet-invite-urls", props.fleet.slug],
  queryFn: () =>
    fleetInviteUrlsService.inviteUrls({
      fleetSlug: props.fleet.slug,
    }),
});

const create = async () => {
  try {
    await fleetInviteUrlsService.createInviteUrl({
      fleetSlug: props.fleet.slug,
      requestBody: form.value,
    });

    refetch();
  } catch (error) {
    console.error(error);
  }
};

const remove = async (inviteUrl: FleetInviteUrl) => {
  try {
    await fleetInviteUrlsService.removeInviteUrl({
      fleetSlug: props.fleet.slug,
      token: inviteUrl.token,
    });

    refetch();
  } catch (error) {
    console.error(error);
  }
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

<script lang="ts">
export default {
  name: "InviteUrlModal",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
