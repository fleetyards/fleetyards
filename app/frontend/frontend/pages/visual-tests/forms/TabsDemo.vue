<script lang="ts">
export default {
  name: "VisualTestsFormsTabsDemo",
};
</script>

<script lang="ts" setup>
import FormTabs from "@/shared/components/base/FormTabs/index.vue";
import FormTab from "@/shared/components/base/FormTabs/Tab/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useForm } from "vee-validate";

// FormTabs marks a tab invalid by matching its `fields` against the form's
// errors, so the interesting state only exists inside a form context - and only
// once the form has been validated. Same trick as ErrorStates.vue: validate up
// front so the marker is on screen without anyone having to type.
const { validate } = useForm({
  validationSchema: {
    title: "required",
    contact: "required|email",
    notes: "required",
  },
  initialValues: {
    title: "Thursday Play Evening",
    contact: "not-an-email",
    notes: "",
  },
});

onMounted(async () => {
  await validate();
});

const hideThird = ref(true);
</script>

<template>
  <p>
    The second tab owns an invalid field and the third owns an empty required
    one, so both carry the marker while the first stays clean. The fourth is
    disabled, and the fifth is hidden until the toggle below reveals it - a
    hidden tab is filtered out rather than rendered as disabled.
  </p>

  <FormTabs query-key="demotab" default-tab="basic">
    <FormTab id="basic" label="Basic" :fields="['title']">
      <div class="row">
        <div class="col-12 col-md-6">
          <FormInput name="title" label="Title (required)" />
        </div>
      </div>
    </FormTab>

    <FormTab id="contact" label="Contact" :fields="['contact']">
      <div class="row">
        <div class="col-12 col-md-6">
          <FormInput name="contact" label="Contact (email)" />
        </div>
      </div>
    </FormTab>

    <FormTab id="notes" label="Notes" :fields="['notes']">
      <div class="row">
        <div class="col-12 col-md-6">
          <FormTextarea name="notes" label="Notes (required)" />
        </div>
      </div>
    </FormTab>

    <FormTab id="locked" label="Locked" disabled>
      <p>Not reachable while the tab is disabled.</p>
    </FormTab>

    <FormTab id="secret" label="Revealed" :hidden="hideThird">
      <p>Only registered once the tab stops being hidden.</p>
    </FormTab>
  </FormTabs>

  <div class="row">
    <div class="col-12">
      <Btn data-test="tabs-toggle-hidden" @click="hideThird = !hideThird">
        {{ hideThird ? "Reveal the hidden tab" : "Hide it again" }}
      </Btn>
    </div>
  </div>

  <p class="text-muted">
    The active tab is written to <code>?demotab=</code> — a distinct key,
    because the default <code>tab</code> would collide with anything else on the
    page that syncs to the URL.
  </p>
</template>
