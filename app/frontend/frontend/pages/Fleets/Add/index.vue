<template>
  <section class="container">
    <ValidationObserver v-slot="{ handleSubmit }" small>
      <form @submit.prevent="handleSubmit(submit)">
        <div class="row justify-content-lg-center">
          <div class="col-12 col-md-6 col-lg-4">
            <h1>{{ t("headlines.fleets.add") }}</h1>
          </div>
        </div>

        <div class="row justify-content-lg-center">
          <div class="col-12 col-md-6 col-lg-4">
            <ValidationProvider
              v-slot="{ errors }"
              vid="fid"
              :rules="{
                required: true,
                fidTaken: true,
                min: 3,
                regex: /^[a-zA-Z0-9\-_]{3,}$/,
              }"
              :name="t('labels.fleet.fid')"
              slim
            >
              <FormInput
                id="fid"
                v-model="form.fid"
                translation-key="fleet.fid"
                :error="errors[0]"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="name"
              :rules="{
                required: true,
                min: 3,
                regex: /^[a-zA-Z0-9\-_\. ]{3,}$/,
              }"
              :name="t('labels.name')"
              slim
            >
              <FormInput
                id="name"
                v-model="form.name"
                translation-key="name"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
        </div>
        <div class="row justify-content-lg-center">
          <div class="col-12 col-md-6 col-lg-4">
            <br />
            <Btn
              :loading="submitting"
              type="submit"
              size="large"
              data-test="fleet-save"
            >
              {{ t("actions.save") }}
            </Btn>
          </div>
        </div>
      </form>
    </ValidationObserver>
  </section>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useNoty } from "@/shared/composables/useNoty";
import FormInput from "@/shared/components/base/FormInput/index.vue";

const { t } = useI18n();

const { displaySuccess, displayAlert } = useNoty(t);

type FleetForm = {
  fid?: string;
  name?: string;
};

const form = ref<FleetForm>({
  fid: undefined,
  name: undefined,
});

const loading = ref(false);
const submitting = ref(false);

const submit = () => {
  this.submitting = true;

  const fleet = await fleetsCollection.create(this.form);

  this.submitting = false;

  if (fleet) {
    this.$comlink.$emit("fleet-create");

    displaySuccess({
      text: this.$t("messages.fleet.create.success"),
    });

    this.$router
      .push({
        name: "fleet",
        params: { slug: fleet.slug },
      })
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(() => {});
  } else {
    displayAlert({
      text: this.$t("messages.fleet.create.failure"),
    });
  }
};
</script>

<script lang="ts">
export default {
  name: "FleetAddPage",
};
</script>
