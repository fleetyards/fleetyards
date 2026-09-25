<script lang="ts">
export default {
  name: "SettingsHangar",
};
</script>

<script lang="ts" setup>
import { useSessionStore } from "@/frontend/stores/session";
import { narrowerAudienceDisabled } from "@/frontend/utils/audienceToggles";
import { type UserUpdateInput } from "@/services/fyApi";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useHangarDefaultSortOptions } from "@/frontend/composables/useHangarDefaultSortOptions";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useForm } from "vee-validate";
import { useUpdateProfile as useUpdateProfileMutation } from "@/services/fyApi";

const { t } = useI18n();

const { displaySuccess } = useAppNotifications();

const sessionStore = useSessionStore();

const submitting = ref(false);

const initialValues = ref<UserUpdateInput>({
  publicHangar: sessionStore.currentUser?.publicHangar,
  publicHangarLoaners: sessionStore.currentUser?.publicHangarLoaners,
  publicHangarStats: sessionStore.currentUser?.publicHangarStats,
  publicWishlist: sessionStore.currentUser?.publicWishlist,
  friendsHangar: sessionStore.currentUser?.friendsHangar,
  friendsHangarStats: sessionStore.currentUser?.friendsHangarStats,
  friendsWishlist: sessionStore.currentUser?.friendsWishlist,
  hideOwner: sessionStore.currentUser?.hideOwner,
  hangarDefaultSort: sessionStore.currentUser?.hangarDefaultSort ?? null,
});

const setupForm = () => {
  initialValues.value = {
    publicHangar: sessionStore.currentUser?.publicHangar,
    publicHangarLoaners: sessionStore.currentUser?.publicHangarLoaners,
    publicHangarStats: sessionStore.currentUser?.publicHangarStats,
    publicWishlist: sessionStore.currentUser?.publicWishlist,
    friendsHangar: sessionStore.currentUser?.friendsHangar,
    friendsHangarStats: sessionStore.currentUser?.friendsHangarStats,
    friendsWishlist: sessionStore.currentUser?.friendsWishlist,
    hideOwner: sessionStore.currentUser?.hideOwner,
    hangarDefaultSort: sessionStore.currentUser?.hangarDefaultSort ?? null,
  };
};

onMounted(() => {
  if (sessionStore.currentUser) {
    setupForm();
  }
});

watch(
  () => sessionStore.currentUser,
  () => {
    setupForm();
  },
);

const comlink = useComlink();

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [publicHangar, publicHangarProps] = defineField("publicHangar");
const [publicHangarLoaners, publicHangarLoanersProps] = defineField(
  "publicHangarLoaners",
);
const [publicHangarStats, publicHangarStatsProps] =
  defineField("publicHangarStats");
const [publicWishlist, publicWishlistProps] = defineField("publicWishlist");
const [friendsHangar, friendsHangarProps] = defineField("friendsHangar");
const [friendsHangarStats, friendsHangarStatsProps] =
  defineField("friendsHangarStats");
const [friendsWishlist, friendsWishlistProps] = defineField("friendsWishlist");
const [hideOwner, hideOwnerProps] = defineField("hideOwner");
const [hangarDefaultSort, hangarDefaultSortProps] =
  defineField("hangarDefaultSort");

const hangarDefaultSortOptions = useHangarDefaultSortOptions();

// See `narrowerAudienceDisabled`: a friend is a member of the public, so while
// the public switch is on the friend one is not consulted at all.
const friendsDisabled = (isPublic: unknown) =>
  narrowerAudienceDisabled(isPublic, submitting.value);

const mutation = useUpdateProfileMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      data: values,
    })
    .then(() => {
      comlink.emit("user-update");

      displaySuccess({
        text: t("messages.updateHangar.success"),
      });
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.hangar") }}</Heading>
  <form id="settings-hangar-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="publicHangar"
          v-bind="publicHangarProps"
          name="publicHangar"
          :label="t('labels.user.publicHangar')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="friendsHangar"
          name="friendsHangar"
          v-bind="friendsHangarProps"
          :disabled="friendsDisabled(publicHangar)"
          :implied="!!publicHangar"
          :label="t('labels.user.friendsHangar')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="publicHangarLoaners"
          name="publicHangarLoaners"
          v-bind="publicHangarLoanersProps"
          :label="t('labels.user.publicHangarLoaners')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="publicHangarStats"
          name="publicHangarStats"
          v-bind="publicHangarStatsProps"
          :label="t('labels.user.publicHangarStats')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="friendsHangarStats"
          name="friendsHangarStats"
          v-bind="friendsHangarStatsProps"
          :disabled="friendsDisabled(publicHangarStats)"
          :implied="!!publicHangarStats"
          :label="t('labels.user.friendsHangarStats')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="publicWishlist"
          name="publicWishlist"
          v-bind="publicWishlistProps"
          :label="t('labels.user.publicWishlist')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="friendsWishlist"
          name="friendsWishlist"
          v-bind="friendsWishlistProps"
          :disabled="friendsDisabled(publicWishlist)"
          :implied="!!publicWishlist"
          :label="t('labels.user.friendsWishlist')"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="hideOwner"
          name="hideOwner"
          v-bind="hideOwnerProps"
          :label="t('labels.user.hideOwner')"
        />
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-6">
        <BaseSelect
          v-model="hangarDefaultSort"
          v-bind="hangarDefaultSortProps"
          :options="hangarDefaultSortOptions"
          :label="t('labels.user.hangarDefaultSort')"
          :info="t('labels.user.hangarDefaultSortInfo')"
          name="hangarDefaultSort"
          :searchable="false"
          :nullable="false"
          unsorted
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="settings-hangar-form"
      hide-cancel
    />
  </form>
</template>
