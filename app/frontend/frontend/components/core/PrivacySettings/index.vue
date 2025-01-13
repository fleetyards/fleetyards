<script lang="ts">
export default {
  name: "PrivacySettings",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { type Cookies } from "@/frontend/stores/cookies";
import { useCookiesStore } from "@/frontend/stores/cookies";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  settings?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  settings: false,
});

const { t } = useI18n();

const info = ref<string | undefined>();

const internalSettings = ref(false);

const form = ref<Cookies>({
  ahoy: false,
  youtube: false,
});

const cookiesStore = useCookiesStore();

const title = computed(() => {
  if (info.value) {
    return t(`privacySettings.info.${info.value}.title`);
  }
  if (internalSettings.value) {
    return t("privacySettings.title");
  }

  return t("privacySettings.introduction.title");
});

const infoLabels = computed(() => {
  return t(`privacySettings.info.${info.value}.data`);
});

watch(
  () => cookiesStore.cookies,
  () => {
    setupForm();
  },
  { deep: true },
);

onMounted(() => {
  internalSettings.value = props.settings;
  setupForm();
});

const showSettings = () => {
  internalSettings.value = true;
};

const comlink = useComlink();

const closeNav = () => {
  comlink.emit("close-modal", true);
};

const setupForm = () => {
  form.value = {
    ahoy: cookiesStore.cookies.ahoy,
    youtube: cookiesStore.cookies.youtube,
  };
};

const submit = () => {
  cookiesStore.updateAcceptedCookies({
    ...form.value,
  });

  cookiesStore.hideInfo();

  closeNav();
};

const accept = () => {
  cookiesStore.updateAcceptedCookies({
    ahoy: true,
    youtube: true,
  });

  cookiesStore.hideInfo();

  closeNav();
};

const openInfo = (key: string) => {
  info.value = key;
};

const hideInfo = () => {
  info.value = undefined;
};
</script>

<template>
  <Modal :title="title" fixed>
    <div v-if="info" class="cookies-banner">
      <p>
        {{ t(`privacySettings.info.${info}.text`) }}
      </p>
      <dl>
        <dt>
          {{ t("privacySettings.info.why") }}
        </dt>
        <dd>
          {{ t(`privacySettings.info.${info}.why`) }}
        </dd>
        <dt>
          {{ t("privacySettings.info.dataCollected") }}
        </dt>
        <dd>
          <ul>
            <li v-for="(item, index) in infoLabels" :key="index">
              {{ item }}
            </li>
          </ul>
        </dd>
        <dt>
          {{ t("privacySettings.info.company") }}
        </dt>
        <dd>
          {{ t(`privacySettings.info.${info}.company`) }}
        </dd>
        <dt>
          {{ t("privacySettings.info.location") }}
        </dt>
        <dd>
          {{ t(`privacySettings.info.${info}.location`) }}
        </dd>
      </dl>
    </div>
    <div v-else-if="internalSettings" class="cookies-banner">
      <p>{{ t(`privacySettings.text`) }}</p>
      <form @submit.prevent="submit">
        <div class="row">
          <div class="col-12">
            <fieldset>
              <legend>{{ t("privacySettings.essential") }}</legend>
              <div class="form-item">
                <FormCheckbox
                  name="fontawesome"
                  :value="true"
                  :label="t('privacySettings.fontawesome')"
                  :disabled="true"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('fontawesome')"
                />
              </div>
              <div class="form-item">
                <FormCheckbox
                  name="googleFonts"
                  :value="true"
                  :label="t('privacySettings.googleFonts')"
                  :disabled="true"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('googleFonts')"
                />
              </div>
            </fieldset>
            <fieldset>
              <legend>{{ t("privacySettings.functional") }}</legend>
              <div class="form-item">
                <Checkbox
                  v-model="form.ahoy"
                  name="ahoy"
                  :label="t('privacySettings.ahoy')"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('ahoy')"
                />
              </div>
              <div class="form-item">
                <Checkbox
                  v-model="form.youtube"
                  name="youtube"
                  :label="t('privacySettings.youtube')"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('youtube')"
                />
              </div>
            </fieldset>
          </div>
        </div>
        <div class="cookies-banner-actions" />
      </form>
    </div>
    <div v-else class="cookies-banner">
      <p>{{ t("privacySettings.introduction.paragraph1") }}</p>
      <p>{{ t("privacySettings.introduction.paragraph2") }}</p>
      <p>
        {{ t("privacySettings.introduction.paragraph3") }}
        <Btn
          :variant="BtnVariantsEnum.LINK"
          :text-inline="true"
          :to="{ name: 'privacy-policy' }"
        >
          {{ t("nav.privacyPolicy") }}
        </Btn>
        .
      </p>
    </div>
    <template #footer>
      <div class="cookies-banner-actions">
        <Btn v-if="info" :inline="true" :block="true" @click="hideInfo">
          <i class="fal fa-chevron-left" />
          {{ t("actions.back") }}
        </Btn>
        <Btn
          v-else-if="internalSettings"
          data-test="save-privacy-settings"
          :block="true"
          :inline="true"
          @click="submit"
        >
          {{ t("privacySettings.save") }}
        </Btn>
        <template v-else>
          <Btn
            data-test="show-settings"
            :inline="true"
            :variant="BtnVariantsEnum.LINK"
            @click="showSettings"
          >
            {{ t("privacySettings.editSettings") }}
          </Btn>
          <Btn data-test="accept-cookies" :inline="true" @click="accept">
            {{ t("privacySettings.accept") }}
          </Btn>
        </template>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
