<template>
  <Modal :title="title">
    <div v-if="info" class="cookies-banner">
      <p>
        {{ $t(`privacySettings.info.${info}.text`) }}
      </p>
      <dl>
        <dt>
          {{ $t("privacySettings.info.why") }}
        </dt>
        <dd>
          {{ $t(`privacySettings.info.${info}.why`) }}
        </dd>
        <dt>
          {{ $t("privacySettings.info.dataCollected") }}
        </dt>
        <dd>
          <ul>
            <li
              v-for="(item, index) in $t(`privacySettings.info.${info}.data`)"
              :key="index"
            >
              {{ item }}
            </li>
          </ul>
        </dd>
        <dt>
          {{ $t("privacySettings.info.company") }}
        </dt>
        <dd>
          {{ $t(`privacySettings.info.${info}.company`) }}
        </dd>
        <dt>
          {{ $t("privacySettings.info.location") }}
        </dt>
        <dd>
          {{ $t(`privacySettings.info.${info}.location`) }}
        </dd>
      </dl>
    </div>
    <div v-else-if="internalSettings" class="cookies-banner">
      <p>{{ $t(`privacySettings.text`) }}</p>
      <form @submit.prevent="submit">
        <div class="row">
          <div class="col-12">
            <fieldset>
              <legend>{{ $t("privacySettings.essential") }}</legend>
              <div class="form-item">
                <Checkbox
                  :value="true"
                  :label="$t('privacySettings.fontawesome')"
                  :disabled="true"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('fontawesome')"
                />
              </div>
              <div class="form-item">
                <Checkbox
                  :value="true"
                  :label="$t('privacySettings.googleFonts')"
                  :disabled="true"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('googleFonts')"
                />
              </div>
            </fieldset>
            <fieldset>
              <legend>{{ $t("privacySettings.functional") }}</legend>
              <div class="form-item">
                <Checkbox
                  v-model="form.ahoy"
                  :label="$t('privacySettings.ahoy')"
                />
                <i
                  class="info-link fal fa-info-circle"
                  @click="openInfo('ahoy')"
                />
              </div>
              <div class="form-item">
                <Checkbox
                  v-model="form.youtube"
                  :label="$t('privacySettings.youtube')"
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
      <p>{{ $t("privacySettings.introduction.paragraph1") }}</p>
      <p>{{ $t("privacySettings.introduction.paragraph2") }}</p>
      <p>
        {{ $t("privacySettings.introduction.paragraph3") }}
        <Btn
          variant="link"
          :text-inline="true"
          :to="{ name: 'privacy-policy' }"
        >
          {{ $t("nav.privacyPolicy") }}
        </Btn>
        .
      </p>
    </div>
    <template #footer>
      <div class="cookies-banner-actions">
        <Btn v-if="info" :inline="true" :block="true" @click.native="hideInfo">
          <i class="fal fa-chevron-left" />
          {{ $t("actions.back") }}
        </Btn>
        <Btn
          v-else-if="internalSettings"
          data-test="save-privacy-settings"
          :block="true"
          :inline="true"
          @click.native="submit"
        >
          {{ $t("privacySettings.save") }}
        </Btn>
        <template v-else>
          <Btn
            data-test="show-settings"
            :inline="true"
            variant="link"
            @click.native="showSettings"
          >
            {{ $t("privacySettings.editSettings") }}
          </Btn>
          <Btn data-test="accept-cookies" :inline="true" @click.native="accept">
            {{ $t("privacySettings.accept") }}
          </Btn>
        </template>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts" setup>
import { ref, computed, watch, onMounted } from "vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/frontend/composables/useComlink";
import { useCookiesStore } from "@/frontend/stores/Cookies";
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import Checkbox from "@/frontend/core/components/Form/Checkbox/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";

interface Props {
  settings?: boolean;
}

type PrivacySettingForm = {
  ahoy: boolean;
  youtube: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  settings: false,
});
const info = ref<string | null>(null);

const internalSettings = ref(false);

const form = ref<PrivacySettingForm>({
  ahoy: false,
  youtube: false,
});

const { t } = useI18n();

const title = computed(() => {
  if (info.value) {
    return t(`privacySettings.info.${info.value}.title`);
  }
  if (internalSettings.value) {
    return t("privacySettings.title");
  }

  return t("privacySettings.introduction.title");
});

const cookiesStore = useCookiesStore();

const setupForm = () => {
  form.value = {
    ahoy: cookiesStore.cookies.ahoy,
    youtube: cookiesStore.cookies.youtube,
  };
};

watch(
  () => cookiesStore.cookies,
  () => {
    setupForm();
  },
  { deep: true }
);

onMounted(() => {
  internalSettings.value = props.settings;

  setupForm();
});

const showSettings = () => {
  internalSettings.value = true;
};

const comlink = useComlink();

const close = () => {
  comlink.$emit("close-modal", "privacySetting", true);
};

const submit = () => {
  cookiesStore.updateAcceptedCookies({
    ...form.value,
  });

  cookiesStore.hideInfo();

  close();
};

const accept = () => {
  cookiesStore.updateAcceptedCookies({
    ahoy: true,
    youtube: true,
  });

  cookiesStore.hideInfo();

  close();
};

const openInfo = (key) => {
  info.value = key;
};

const hideInfo = () => {
  info.value = null;
};
</script>

<script lang="ts">
export default {
  name: "PrivacySettings",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
