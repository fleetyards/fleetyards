<script lang="ts">
export default {
  name: "AdminFleetEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type Fleet,
  type FleetInput,
  useUpdateFleet,
  getFleetsQueryKey,
  getFleetQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<FleetInput>({
  name: props.fleet.name,
  fid: props.fleet.fid,
  description: props.fleet.description,
  publicFleet: props.fleet.publicFleet,
  publicFleetStats: props.fleet.publicFleetStats,
  discord: props.fleet.discord,
  guilded: props.fleet.guilded,
  homepage: props.fleet.homepage,
  twitch: props.fleet.twitch,
  youtube: props.fleet.youtube,
  ts: props.fleet.ts,
  rsiSid: props.fleet.rsiSid,
});

const validationSchema = {
  name: "required",
  fid: "required",
};

const { defineField, handleSubmit, meta } = useForm<FleetInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [fid, fidProps] = defineField("fid");
const [description, descriptionProps] = defineField("description");
const [publicFleet, publicFleetProps] = defineField("publicFleet");
const [publicFleetStats, publicFleetStatsProps] =
  defineField("publicFleetStats");
const [discord, discordProps] = defineField("discord");
const [guilded, guildedProps] = defineField("guilded");
const [homepage, homepageProps] = defineField("homepage");
const [twitch, twitchProps] = defineField("twitch");
const [youtube, youtubeProps] = defineField("youtube");
const [ts, tsProps] = defineField("ts");
const [rsiSid, rsiSidProps] = defineField("rsiSid");
const [logo, logoProps] = defineField("logo");
const [backgroundImage, backgroundImageProps] = defineField("backgroundImage");

const submitting = ref(false);

const updateMutation = useUpdateFleet({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getFleetsQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getFleetQueryKey(props.fleet.id),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.fleet.id, data: values })
    .catch((error) => {
      console.error("Error updating fleet:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-fleets",
      hash: `#${props.fleet.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.fleets.edit") }}</Heading>
  <form id="admin-fleet-edit-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="name" v-bind="nameProps" name="name" />
        <FormInput
          v-model="fid"
          v-bind="fidProps"
          translation-key="fleet.fid"
          name="fid"
        />
        <FormInput
          v-model="description"
          v-bind="descriptionProps"
          translation-key="fleet.description"
          name="description"
        />
        <FormInput
          v-model="rsiSid"
          v-bind="rsiSidProps"
          translation-key="fleet.rsiSid"
          name="rsiSid"
        />
        <FormFileInput
          v-model="logo"
          v-bind="logoProps"
          :file="fleet.logo"
          translation-key="fleet.logo"
          name="logo"
          :allowed-types="AllowedFileTypes.IMAGE"
          avatar
          clearable
        />
        <FormFileInput
          v-model="backgroundImage"
          v-bind="backgroundImageProps"
          :file="fleet.backgroundImage"
          translation-key="fleet.backgroundImage"
          name="backgroundImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
      </div>
      <div class="col-12 col-md-6">
        <div class="row">
          <div class="col-12 col-md-6">
            <FormToggle
              v-model="publicFleet"
              v-bind="publicFleetProps"
              translation-key="fleet.publicFleet"
              name="publicFleet"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormToggle
              v-model="publicFleetStats"
              v-bind="publicFleetStatsProps"
              translation-key="fleet.publicFleetStats"
              name="publicFleetStats"
            />
          </div>
        </div>
        <hr />
        <FormInput
          v-model="discord"
          v-bind="discordProps"
          translation-key="fleet.discord.url"
          name="discord"
        />
        <FormInput
          v-model="guilded"
          v-bind="guildedProps"
          translation-key="fleet.guilded"
          name="guilded"
        />
        <FormInput
          v-model="homepage"
          v-bind="homepageProps"
          translation-key="fleet.homepage"
          name="homepage"
        />
        <FormInput
          v-model="twitch"
          v-bind="twitchProps"
          translation-key="fleet.twitch"
          name="twitch"
        />
        <FormInput
          v-model="youtube"
          v-bind="youtubeProps"
          translation-key="fleet.youtube"
          name="youtube"
        />
        <FormInput
          v-model="ts"
          v-bind="tsProps"
          translation-key="fleet.ts"
          name="ts"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="admin-fleet-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
