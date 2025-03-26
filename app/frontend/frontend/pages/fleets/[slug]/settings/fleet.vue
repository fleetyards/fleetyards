<script lang="ts">
export default {
  name: "FleetSettingsPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useForm } from "vee-validate";
import Btn from "@/shared/components/base/Btn/index.vue";
// import Avatar from "@/frontend/core/components/Avatar/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import {
  type Fleet,
  type FleetMember,
  type FleetUpdateInput,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const submitting = ref(false);

const deleting = ref(false);

const initialValues = ref<FleetUpdateInput>({
  fid: props.fleet.fid,
  name: props.fleet.name,
  description: props.fleet.description,
  rsiSid: props.fleet.rsiSid,
  discord: props.fleet.discord,
  ts: props.fleet.ts,
  homepage: props.fleet.homepage,
  twitch: props.fleet.twitch,
  youtube: props.fleet.youtube,
  guilded: props.fleet.guilded,
  publicFleet: props.fleet.publicFleet,
  publicFleetStats: props.fleet.publicFleetStats,
});

const validationSchema = {
  fid: "required",
  name: "required",
};

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const [fid, fidProps] = defineField("fid");
const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [rsiSid, rsiSidProps] = defineField("rsiSid");
const [discord, discordProps] = defineField("discord");
const [ts, tsProps] = defineField("ts");
const [homepage, homepageProps] = defineField("homepage");
const [twitch, twitchProps] = defineField("twitch");
const [youtube, youtubeProps] = defineField("youtube");
const [guilded, guildedProps] = defineField("guilded");
const [publicFleet, publicFleetProps] = defineField("publicFleet");
const [publicFleetStats, publicFleetStatsProps] =
  defineField("publicFleetStats");

// // eslint-disable-next-line @typescript-eslint/no-explicit-any
// files: any[] = [];

// fileExtensions = "jpg,jpeg,png,webp";

// acceptedMimeTypes = "image/png,image/jpeg,image/webp";

// form: FleetForm = {
//   fid: null,
//   name: null,
//   description: null,
//   rsiSid: null,
//   discord: null,
//   ts: null,
//   homepage: null,
//   twitch: null,
//   youtube: null,
//   guilded: null,
//   publicFleet: false,
//   publicFleetStats: false,
//   removeLogo: false,
// };

// get fleet() {
//   return fleetsCollection.record;
// }

// get metaTitle() {
//   if (!this.fleet) {
//     return null;
//   }

//   return this.$t("title.fleets.settings", { fleet: this.fleet.name });
// }

// get logoUrl() {
//   if (this.fleet) {
//     return this.newLogo.url || this.fleet.logo;
//   }

//   return this.newLogo.url;
// }

// get newLogo() {
//   return (this.files && this.files[0]) || {};
// }

// get canEdit() {
//   return this.fleet?.myRole === "admin";
// }

// get leaveTooltip() {
//   if (this.canEdit) {
//     return this.$t("texts.fleets.leaveInfo");
//   }

//   return null;
// }

// @Watch("$route")
// onRouteChange() {
//   this.fetch();
// }

// @Watch("fleet")
// onFleetChange() {
//   this.setupForm();
// }

// mounted() {
//   this.fetch();

//   if (this.fleet && !this.canEdit) {
//     this.$router.replace({
//       name: "fleet-settings-membership",
//       params: { slug: this.$route.params.slug },
//     });
//     return;
//   }

//   if (this.fleet) {
//     this.setupForm();
//   }
// }

// selectLogo() {
//   this.form.removeLogo = false;
//   this.$refs.upload.$el.querySelector("input").click();
// }

// removeLogo() {
//   this.files = [];
//   this.fleet.logo = null;
//   this.form.removeLogo = true;
// }

// setupForm() {
//   this.form = {
//     fid: this.fleet.fid,
//     rsiSid: this.fleet.rsiSid,
//     name: this.fleet.name,
//     description: this.fleet.description,
//     discord: this.fleet.discord,
//     ts: this.fleet.ts,
//     homepage: this.fleet.homepage,
//     twitch: this.fleet.twitch,
//     youtube: this.fleet.youtube,
//     guilded: this.fleet.guilded,
//     publicFleet: this.fleet.publicFleet,
//     publicFleetStats: this.fleet.publicFleetStats,
//     removeLogo: false,
//   };
// }

// async submit() {
//   this.submitting = true;

//   await this.uploadLogo();

//   const response = await this.$api.put(
//     `fleets/${this.$route.params.slug}`,
//     this.form,
//   );

//   this.submitting = false;

//   if (!response.error) {
//     displaySuccess({
//       text: this.$t("messages.fleet.update.success"),
//     });

//     this.$comlink.$emit("fleet-update");

//     if (response.data.slug !== this.$route.params.slug) {
//       await this.$router.replace({
//         name: "fleet-settings",
//         params: { slug: response.data.slug },
//       });
//     }
//   } else {
//     this.handleUpdateError(response.error);
//   }
// }

// async uploadLogo() {
//   if (!this.newLogo || !this.newLogo.file) {
//     return;
//   }

//   const uploadData = new FormData();
//   uploadData.append("logo", this.newLogo.file);

//   const response = await this.$api.upload(
//     `fleets/${this.$route.params.slug}`,
//     uploadData,
//   );

//   if (!response.error) {
//     displaySuccess({
//       text: this.$t("messages.fleet.update.logo.success"),
//     });

//     this.$comlink.$emit("fleet-update");

//     setTimeout(() => {
//       this.files = [];
//     }, 1000);
//   } else {
//     this.handleUpdateError(response.error);
//   }
// }

// handleUpdateError(error) {
//   if (error.response && error.response.data) {
//     const { data: errorData } = error.response;

//     this.$refs.form.setErrors(transformErrors(errorData.errors));

//     displayAlert({
//       text: errorData.message,
//     });
//   } else {
//     displayAlert({
//       text: this.$t("messages.fleet.update.failure"),
//     });
//   }
// }

// updatedValue(value) {
//   this.files = value;
// }

// inputFilter(newFile, oldFile, prevent) {
//   if (newFile && !oldFile) {
//     if (!/\.(gif|jpg|jpeg|png|webp)$/i.test(newFile.name)) {
//       this.alert("Your choice is not a picture");
//       return prevent();
//     }
//   }
//   if (newFile && (!oldFile || newFile.file !== oldFile.file)) {
//     // eslint-disable-next-line no-param-reassign
//     newFile.url = "";
//     const URL = window.URL || window.webkitURL;
//     if (URL && URL.createObjectURL) {
//       // eslint-disable-next-line no-param-reassign
//       newFile.url = URL.createObjectURL(newFile.file);
//     }
//   }

//   return null;
// }

// async fetch() {
//   await fleetsCollection.findBySlug(this.$route.params.slug);
// }

const onSubmit = handleSubmit((values) => {});

const onDestroy = async () => {
  deleting.value = true;

  // displayConfirm({
  //   text: this.$t("messages.confirm.fleet.destroy"),
  //   onConfirm: async () => {
  //     const response = await this.$api.destroy(
  //       `fleets/${this.$route.params.slug}`,
  //     );

  //     if (!response.error) {
  //       // eslint-disable-next-line @typescript-eslint/no-empty-function
  //       this.$router.push({ name: "home" }).catch(() => {});

  //       this.$comlink.$emit("fleet-update");

  //       displaySuccess({
  //         text: this.$t("messages.fleet.destroy.success"),
  //       });
  //     } else {
  //       displayAlert({
  //         text: this.$t("messages.fleet.destroy.failure"),
  //       });
  //       this.deleting = false;
  //     }
  //   },
  //   onClose: () => {
  //     this.deleting = false;
  //   },
  // });
};
</script>

<template>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="fid"
          name="fid"
          :label="t('labels.fleet.fid')"
          v-bind="fidProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput v-model="name" name="name" v-bind="nameProps" />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <FormTextarea
          v-model="description"
          name="description"
          v-bind="descriptionProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="rsiSid"
          name="rsiSid"
          icon="icon icon-rsi icon-label"
          translation-key="fleet.rsiSid"
          v-bind="rsiSidProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="publicFleet"
          name="publicFLeet"
          translation-key="fleet.public"
          v-bind="publicFleetProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormCheckbox
          v-model="publicFleetStats"
          name="publicFleetStats"
          translation-key="fleet.publicStats"
          v-bind="publicFleetStatsProps"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="homepage" name="homepage" v-bind="homepageProps" />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="ts"
          name="ts"
          icon="fab fa-teamspeak"
          translation-key="fleet.ts"
          v-bind="tsProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="discord"
          name="discord"
          icon="fab fa-discord"
          v-bind="discordProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="guilded"
          name="guilded"
          icon="fab fa-guilded"
          v-bind="guildedProps"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="twitch"
          name="twitch"
          icon="fab fa-twitch"
          v-bind="twitchProps"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="youtube"
          name="youtube"
          icon="fab fa-youtube"
          v-bind="youtubeProps"
        />
      </div>
    </div>
    <hr />
    <Btn
      :loading="submitting"
      type="submit"
      size="large"
      data-test="fleet-save"
    >
      {{ t("actions.save") }}
    </Btn>
    <Btn
      :loading="deleting"
      size="large"
      variant="danger"
      data-test="fleet-delete"
      @click="onDestroy"
    >
      {{ t("actions.delete") }}
    </Btn>
  </form>
</template>
