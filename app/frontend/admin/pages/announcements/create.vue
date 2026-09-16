<script lang="ts">
export default {
  name: "AdminAnnouncementCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import {
  type AnnouncementInput,
  AnnouncementInputStatusEnum,
  useCreateAnnouncement,
  getAnnouncementsQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import AnnouncementChannelFields from "@/admin/components/Announcements/ChannelFields/index.vue";
import AnnouncementPartsEditor from "@/admin/components/Announcements/PartsEditor/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

type FormValues = {
  title: string;
  body: string;
  link?: string;
  publishAt?: string;
  notifyUsers: boolean;
  postDiscord: boolean;
  postBluesky: boolean;
  postX: boolean;
};

const schedule = ref(false);

// publishAt is required only once scheduling is on. Without the rule the form
// submits an empty date and the API answers with the model's own validation
// error -- a round trip to say what the field could have said itself.
const validationSchema = computed(() => ({
  title: "required",
  body: "required",
  ...(schedule.value ? { publishAt: "required" } : {}),
}));

const { defineField, handleSubmit, meta, values } = useForm<FormValues>({
  initialValues: {
    title: "",
    body: "",
    link: undefined,
    publishAt: undefined,
    notifyUsers: true,
    postDiscord: true,
    postBluesky: false,
    postX: false,
  },
  validationSchema,
});

const [title, titleProps] = defineField("title");
const [body, bodyProps] = defineField("body");
const [link, linkProps] = defineField("link");
const [publishAt, publishAtProps] = defineField("publishAt");
const [notifyUsers] = defineField("notifyUsers");
const [postDiscord] = defineField("postDiscord");
const [postBluesky] = defineField("postBluesky");
const [postX] = defineField("postX");

const noChannel = computed(
  () =>
    !values.notifyUsers &&
    !values.postDiscord &&
    !values.postBluesky &&
    !values.postX,
);

// The schedule switch is not a form field, so meta.dirty does not see it.
const scheduleDirty = computed(() => schedule.value);

const discordParts = ref<string[]>([]);
const socialParts = ref<string[]>([]);

const partsDirty = computed(
  () => discordParts.value.length > 0 || socialParts.value.length > 0,
);

const submitting = ref(false);

const createMutation = useCreateAnnouncement({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getAnnouncementsQueryKey(),
      });
    },
  },
});

const onSubmit = handleSubmit(async (formValues) => {
  if (noChannel.value) {
    displayAlert({ text: t("labels.admin.announcements.noChannel") });
    return;
  }

  submitting.value = true;

  const payload: AnnouncementInput = {
    title: formValues.title,
    body: formValues.body,
    discordParts: discordParts.value,
    socialParts: socialParts.value,
    link: formValues.link || undefined,
    status: schedule.value
      ? AnnouncementInputStatusEnum.SCHEDULED
      : AnnouncementInputStatusEnum.DRAFT,
    // FormDateTime hands back local time, and the schema wants RFC 3339.
    publishAt:
      schedule.value && formValues.publishAt
        ? new Date(formValues.publishAt).toISOString()
        : undefined,
    notifyUsers: formValues.notifyUsers,
    postDiscord: formValues.postDiscord,
    postBluesky: formValues.postBluesky,
    postX: formValues.postX,
  };

  await createMutation
    .mutateAsync({ data: payload })
    .then(async () => {
      displaySuccess({ text: t("messages.announcement.created") });
      await router.push(extend({ name: "admin-announcements" }));
    })
    .catch((error) => {
      console.error("Error creating announcement:", error);
      displayAlert({ text: t("messages.announcement.createFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-announcements" }));
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-announcements' },
        label: t('headlines.admin.announcements.index'),
      },
    ]"
  />
  <Heading hero>{{ t("headlines.admin.announcements.new") }}</Heading>
  <form id="admin-announcement-create-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-7">
        <FormInput
          v-model="title"
          v-bind="titleProps"
          translation-key="announcement.title"
          name="title"
        />
        <FormTextarea
          v-model="body"
          v-bind="bodyProps"
          translation-key="announcement.body"
          name="body"
        />
        <FormInput
          v-model="link"
          v-bind="linkProps"
          translation-key="announcement.link"
          name="link"
        />

        <AnnouncementPartsEditor
          v-model="discordParts"
          name="discord-parts"
          :label="t('labels.announcement.discordParts')"
          :hint="t('labels.admin.announcements.discordPartsInfo')"
          :part-placeholder="t('placeholders.announcement.discordPart')"
          :limits="[{ label: 'Discord', limit: 2000 }]"
        />

        <AnnouncementPartsEditor
          v-model="socialParts"
          name="social-parts"
          :label="t('labels.announcement.socialParts')"
          :hint="t('labels.admin.announcements.socialPartsInfo')"
          :part-placeholder="t('placeholders.announcement.socialPart')"
          :limits="[
            { label: 'X', limit: 280, weighted: true },
            { label: 'Bluesky', limit: 300 },
          ]"
        />
      </div>
      <div class="col-12 col-md-5">
        <AnnouncementChannelFields
          v-model:notify-users="notifyUsers"
          v-model:post-discord="postDiscord"
          v-model:post-bluesky="postBluesky"
          v-model:post-x="postX"
        />
        <p v-if="noChannel" class="announcement-form__warning">
          {{ t("labels.admin.announcements.noChannel") }}
        </p>
        <FormToggle
          v-model="schedule"
          name="schedule"
          translation-key="announcement.schedule"
          no-placeholder
        />
        <FormDateTime
          v-if="schedule"
          v-model="publishAt"
          v-bind="publishAtProps"
          translation-key="announcement.publishAt"
          name="publishAt"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="admin-announcement-create-form"
      :dirty="meta.dirty || meta.touched || scheduleDirty || partsDirty"
      @cancel="handleCancel"
    />
  </form>
</template>

<style lang="scss" scoped>
.announcement-form__warning {
  color: $danger;
  margin: 0 0 16px;
}
</style>
