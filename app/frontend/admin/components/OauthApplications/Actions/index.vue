<script lang="ts">
export default {
  name: "OauthApplicationActions",
};
</script>

<script lang="ts" setup>
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Items from "@/admin/components/OauthApplications/Actions/Items.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { type OauthApplication } from "@/services/fyAdminApi";

type Props = {
  oauthApplication: OauthApplication;
};

const props = defineProps<Props>();

const mobile = useMobile();
</script>

<template>
  <BtnDropdown v-if="mobile" :size="BtnSizesEnum.SMALL" inline>
    <Items :oauth-application="props.oauthApplication" with-labels />
  </BtnDropdown>
  <BtnGroup v-else inline>
    <Items :oauth-application="props.oauthApplication" />
  </BtnGroup>
</template>
