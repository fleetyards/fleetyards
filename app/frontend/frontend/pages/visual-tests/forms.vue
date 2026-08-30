<script lang="ts">
export default {
  name: "VisualTestsFormsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import FormDateTime from "@/shared/components/base/FormDateTime/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormInputGroup from "@/shared/components/base/FormInputGroup/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import RadioList from "@/shared/components/base/RadioList/index.vue";
import Slider from "@/shared/components/base/Slider/index.vue";
import Toggle from "@/shared/components/base/Toggle/index.vue";
import ErrorStates from "@/frontend/pages/visual-tests/forms/ErrorStates.vue";
import TabsDemo from "@/frontend/pages/visual-tests/forms/TabsDemo.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import {
  InputAlignmentsEnum,
  InputSizesEnum,
  InputTypesEnum,
  InputVariantsEnum,
} from "@/shared/components/base/FormInput/types";
import { type FilterOption } from "@/services/fyApi";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { displaySuccess } = useAppNotifications();

const text = ref("Aegis Dynamics");
const number = ref(42);
const password = ref("hunter2");
const email = ref("pilot@fleetyards.net");
const url = ref("https://fleetyards.net");
const color = ref("#ffcc00");
const clearable = ref("Clear me");
const prefixed = ref(1250);
const empty = ref<string | null>(null);
const dateTime = ref<string | null>("2029-06-14T19:30:00.000Z");
const dateOnly = ref<string | null>("2029-06-14T00:00:00.000Z");
const dateTimeEmpty = ref<string | null>(null);
const large = ref("Large size");
const clean = ref("Clean variant");
const rightAligned = ref(998);

const textarea = ref(
  "The Galaxy is a modular multi-role ship. Swap the module to change what the ship does.",
);

const checkbox = ref(true);
const checkboxUnchecked = ref(false);
const checkboxGroup = ref<string[]>(["cargo"]);
const toggleField = ref(true);

const date = ref("2026-08-12");

const file = ref<string | null>(null);

const radio = ref("medium");

const sliderValue = ref(40);
const sliderStepped = ref(4);

const toggleActive = ref(true);
const toggleLoading = ref(false);

const filterSingle = ref<string | null>("medium");

const filterMultiple = ref<string[]>(["small", "large"]);

const sizes = [
  { label: "Small", value: "small" },
  { label: "Medium", value: "medium" },
  { label: "Large", value: "large" },
  { label: "Capital", value: "capital" },
];

// RadioList and FilterGroup type their options differently — RadioList requires
// a non-null string value, FilterGroup allows null.
const radioOptions = sizes;
const sizeOptions: FilterOption[] = sizes;

const rdText = ref<string>("Caterpillar");

const rdPrefixed = ref<string>("1200");

const rdError = ref<string>("Zeus");

const rdArea = ref<string>("");

const rdCheck = ref<boolean>(true);

const rdToggle = ref<boolean>(false);

const rdShowError = ref<boolean>(false);

const rdRadio = ref<string>("medium");

const submitting = ref(false);

// Tracked so a pending fake round-trip cannot resolve after the page is gone and
// push its notification onto whatever route the user landed on.
const timers: ReturnType<typeof setTimeout>[] = [];

const later = (callback: () => void, delay: number) => {
  timers.push(setTimeout(callback, delay));
};

onBeforeUnmount(() => {
  timers.forEach(clearTimeout);
});

const onSubmit = () => {
  submitting.value = true;

  later(() => {
    submitting.value = false;
    displaySuccess({ text: "Form submitted." });
  }, 1500);
};

const onCancel = () => {
  displaySuccess({ text: "Form cancelled." });
};

const toggleTheToggle = () => {
  toggleActive.value = !toggleActive.value;
};

const fireToggleLoading = () => {
  toggleLoading.value = true;

  later(() => {
    toggleLoading.value = false;
  }, 2000);
};

const sliderMarks = (value: number) =>
  value % 25 === 0 ? { label: `${value}%` } : false;

const sliderTooltip = (value: number) => `${value}%`;

const powerMarks = (value: number) => ({ label: String(value) });
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">FormInput | Types</Heading>
  <p>Every input type the component supports, each bound to live state.</p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput v-model="text" name="text" label="Text" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="number"
        name="number"
        label="Number"
        :type="InputTypesEnum.NUMBER"
        :step="1"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="password"
        name="password"
        label="Password"
        :type="InputTypesEnum.PASSWORD"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="email"
        name="email"
        label="Email"
        :type="InputTypesEnum.EMAIL"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="url"
        name="url"
        label="URL"
        :type="InputTypesEnum.URL"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="color"
        name="color"
        label="Color"
        :type="InputTypesEnum.COLOR"
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormInput | Variations</Heading>
  <p>
    Sizes, variants, alignment, affixes, icon labels and the clearable,
    placeholder-only and disabled states.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="large"
        name="large"
        label="Large"
        :size="InputSizesEnum.LARGE"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="clean"
        name="clean"
        label="Clean"
        :variant="InputVariantsEnum.CLEAN"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="rightAligned"
        name="right-aligned"
        label="Right aligned"
        :type="InputTypesEnum.NUMBER"
        :alignment="InputAlignmentsEnum.RIGHT"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="clearable"
        name="clearable"
        label="Clearable"
        clearable
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="prefixed"
        name="prefixed"
        label="With affixes"
        :type="InputTypesEnum.NUMBER"
        prefix="UEC"
        suffix="/ SCU"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="text"
        name="with-icon"
        label="With icon"
        icon="fa-duotone fa-rocket"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput
        v-model="empty"
        name="placeholder-only"
        label="Hidden until filled"
        placeholder="Search ships…"
        hide-label-on-empty
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormInput v-model="text" name="disabled" label="Disabled" disabled />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormInputGroup</Heading>
  <p>An input with a button glued to its trailing edge, baseline aligned.</p>
  <div class="row">
    <div class="col-12 col-md-6">
      <FormInputGroup>
        <FormInput v-model="text" name="grouped" label="RSI Handle" />
        <Btn>Verify</Btn>
      </FormInputGroup>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormTextarea</Heading>
  <p>Default and disabled.</p>
  <div class="row">
    <div class="col-12 col-md-6">
      <FormTextarea v-model="textarea" name="textarea" label="Description" />
    </div>
    <div class="col-12 col-md-6">
      <FormTextarea
        v-model="textarea"
        name="textarea-disabled"
        label="Description (disabled)"
        disabled
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormCheckbox & FormToggle</Heading>
  <p>
    Checked, unchecked, partial (the select-all tri-state), disabled, inline,
    and a multi-value group sharing one array.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormCheckbox v-model="checkbox" name="checked" label="Checked" />
      <FormCheckbox
        v-model="checkboxUnchecked"
        name="unchecked"
        label="Unchecked"
      />
      <FormCheckbox name="partial" label="Partial" partial />
      <FormCheckbox
        v-model="checkbox"
        name="checkbox-disabled"
        label="Disabled"
        disabled
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormCheckbox
        v-model="checkboxGroup"
        name="focus"
        label="Cargo"
        checkbox-value="cargo"
      />
      <FormCheckbox
        v-model="checkboxGroup"
        name="focus"
        label="Combat"
        checkbox-value="combat"
      />
      <FormCheckbox
        v-model="checkboxGroup"
        name="focus"
        label="Exploration"
        checkbox-value="exploration"
      />
      <p class="text-muted">Selected: {{ checkboxGroup.join(", ") || "—" }}</p>
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormCheckbox name="inline-a" label="Inline A" inline />
      <FormCheckbox name="inline-b" label="Inline B" inline />
      <FormCheckbox name="no-label" no-label inline />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormToggle v-model="toggleField" name="toggle-field" label="Public" />
      <FormToggle
        v-model="toggleField"
        name="toggle-field-disabled"
        label="Public (disabled)"
        disabled
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormDatePicker</Heading>
  <p>Bound to an ISO date string.</p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormDatePicker v-model="date" name="date" label="Bought at" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDatePicker
        v-model="date"
        name="disabledDate"
        label="Disabled"
        disabled
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <p class="text-muted">Value: {{ date || "—" }}</p>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormDateTime</Heading>
  <p>
    Date and time in one control, bound to an ISO string. The displayed format
    follows the signed-in user's setting, so it reads as
    <code>dd.mm.yyyy</code> or <code>mm/dd/yyyy</code> for the same value.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime v-model="dateTime" name="startsAt" label="Starts at" />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateOnly"
        name="dateOnly"
        label="Date only"
        :enable-time-picker="false"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateTimeEmpty"
        name="emptyDateTime"
        label="Empty, not clearable"
        :clearable="false"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateTime"
        name="disabledDateTime"
        label="Disabled"
        disabled
      />
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateTimeEmpty"
        name="invalidDateTime"
        label="With an error"
        error-message="Pick a date after today"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FormDateTime
        v-model="dateTime"
        name="hourlyDateTime"
        label="Whole hours only"
        :minutes-increment="60"
      />
    </div>
    <div class="col-12 col-md-6">
      <p class="text-muted">Value: {{ dateTime || "—" }}</p>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FormTabs</Heading>
  <TabsDemo />

  <Heading :level="HeadingLevelEnum.H2">FormFileInput</Heading>
  <p>The drop target, plus the avatar and transparent variants.</p>
  <div class="row">
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="file"
        name="image"
        label="Image"
        :allowed-types="AllowedFileTypes.IMAGE"
        :allowed-size-mb="5"
        clearable
      />
    </div>
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="file"
        name="disabledImage"
        label="Disabled"
        :allowed-types="AllowedFileTypes.IMAGE"
        :allowed-size-mb="5"
        disabled
      />
    </div>
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="file"
        name="avatar"
        label="Avatar"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
        avatar
      />
    </div>
    <div class="col-12 col-md-4">
      <FormFileInput
        v-model="file"
        name="transparent"
        label="Transparent"
        :allowed-types="AllowedFileTypes.IMAGE"
        transparent
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">RadioList</Heading>
  <p>Inline and stacked, with and without a reset option.</p>
  <div class="row">
    <div class="col-12 col-md-4">
      <RadioList
        v-model="radio"
        name="size-inline"
        label="Ship Size"
        :options="radioOptions"
      />
    </div>
    <div class="col-12 col-md-4">
      <RadioList
        v-model="radio"
        name="size-reset"
        label="Ship Size (resettable)"
        reset-label="Any"
        :options="radioOptions"
      />
    </div>
    <div class="col-12 col-md-4">
      <RadioList
        v-model="radio"
        name="size-stacked"
        label="Ship Size (stacked, disabled)"
        :options="radioOptions"
        :inline="false"
        disabled
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">FilterGroup</Heading>
  <p>
    Single select, multi select with the selected-options rail, searchable, and
    disabled. Options are static here — in the app they usually come from a
    paginated query.
  </p>
  <div class="row">
    <div class="col-12 col-md-6 col-lg-3">
      <FilterGroup
        v-model="filterSingle"
        name="filter-single"
        label="Ship Size"
        :options="sizeOptions"
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FilterGroup
        v-model="filterMultiple"
        name="filter-multiple"
        label="Ship Sizes"
        :options="sizeOptions"
        multiple
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FilterGroup
        v-model="filterSingle"
        name="filter-searchable"
        label="Ship Size (searchable)"
        search-label="Find a size…"
        :options="sizeOptions"
        searchable
      />
    </div>
    <div class="col-12 col-md-6 col-lg-3">
      <FilterGroup
        v-model="filterSingle"
        name="filter-disabled"
        label="Ship Size (disabled)"
        :options="sizeOptions"
        disabled
      />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">
    Form controls — what the language still owes
  </Heading>
  <p>
    Every control now carries the language itself, which is why everything above
    this heading looks like it too — there is no "before" left to scroll up to.
    What remains here is page-local CSS for the two things the components cannot
    express yet: an error message needs an element they do not emit, and
    aligning a checkbox beside a field needs a label they do not have.
  </p>
  <p>
    The one idea: <strong>the cap carries the state</strong>. That is not new —
    <code>Panel</code> already says “the cap carries the tone; the frame stays
    neutral”, and <code>Btn</code> rests its cap at
    <code>--color-endcap</code> and turns it <code>--color-primary</code> on
    hover, active and focus-visible. Applied to a form: grey at rest, primary on
    focus, danger on error, and the frame never shouts.
  </p>
  <p class="text-muted">
    Two consequences worth seeing. An <code>&lt;input&gt;</code> is a replaced
    element and renders no pseudo-elements, so the frame and the caps move to
    <code>.base-input__wrapper</code> — which makes prefix, field and suffix one
    control instead of three boxes. And the radio's
    <code>display: none</code> becomes <code>opacity: 0</code>, which is the
    whole fix for it being unreachable by keyboard: tab into the row below and
    the focus is visible for the first time.
  </p>
  <div class="form-redesign">
    <div class="row">
      <div class="col-12 col-md-6 col-lg-3">
        <FormInput v-model="rdText" name="rd-text" label="Ship name" />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <FormInput
          v-model="rdPrefixed"
          name="rd-prefixed"
          label="Price"
          prefix="¤"
          suffix="UEC"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <FormInput
          v-model="rdError"
          name="rd-error"
          label="With an error"
          :error-messages="['Not a known ship']"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <FormInput
          v-model="rdText"
          name="rd-disabled"
          label="Disabled"
          disabled
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-6">
        <FormTextarea
          v-model="rdArea"
          name="rd-area"
          label="Notes"
          placeholder="Anything worth remembering"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormCheckbox v-model="rdCheck" name="rd-check" label="Purchased" />
        <FormToggle v-model="rdToggle" name="rd-toggle" label="Public hangar" />
        <RadioList
          v-model="rdRadio"
          name="rd-radio"
          label="Size"
          :options="radioOptions"
          :inline="true"
        />
      </div>
    </div>
    <p class="text-muted">
      The sizes, and the states that are not reachable by pointing at them.
    </p>
    <div class="row">
      <div class="col-12 col-md-6 col-lg-3">
        <FormInput
          v-model="rdText"
          name="rd-medium"
          label="Medium"
          :size="InputSizesEnum.MEDIUM"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <FormInput
          v-model="rdText"
          name="rd-large"
          label="Large"
          :size="InputSizesEnum.LARGE"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <FormCheckbox
          v-model="rdCheck"
          name="rd-check-disabled"
          label="Disabled, checked"
          disabled
        />
        <FormToggle
          v-model="rdToggle"
          name="rd-toggle-disabled"
          label="Disabled toggle"
          disabled
        />
      </div>
      <div class="col-12 col-md-6 col-lg-3">
        <RadioList
          v-model="rdRadio"
          name="rd-radio-disabled"
          label="Disabled group"
          :options="radioOptions"
          :inline="true"
          disabled
        />
      </div>
    </div>
    <p class="text-muted">
      D8, mocked. A field renders no message element at all today — the text
      below is hand-written markup standing in for what the component would
      produce, because CSS cannot show content that does not exist.
    </p>
    <p class="text-muted">
      Flip the switch. The message's line is reserved whether or not there is
      anything to say, so the field below it never moves — chosen over letting
      it appear or animate open, both of which shift what is under them at the
      moment a user is reading or typing.
    </p>
    <FormToggle
      v-model="rdShowError"
      name="rd-show-error"
      label="Fail validation"
    />
    <div class="row">
      <div class="col-12 col-md-8 col-lg-5">
        <FormInput
          v-model="rdError"
          name="rd-msg-reserved"
          label="Ship name"
          :error-messages="rdShowError ? ['Not a known ship'] : []"
        />
        <p class="field-message field-message--reserved">
          {{ rdShowError ? "Not a known ship" : "" }}
        </p>
        <FormInput v-model="rdText" name="rd-msg-next" label="Next field" />
      </div>
    </div>
    <p class="text-muted">
      Alignment in a mixed row. The first pair is what happens today; the second
      reserves the label's line for the control that has none.
    </p>
    <div class="row">
      <div class="col-6 col-lg-3">
        <FormInput v-model="rdText" name="rd-align-a" label="Ship name" />
      </div>
      <div class="col-6 col-lg-3">
        <FormCheckbox v-model="rdCheck" name="rd-align-b" label="Purchased" />
      </div>
      <div class="col-6 col-lg-3">
        <FormInput v-model="rdText" name="rd-align-c" label="Ship name" />
      </div>
      <div class="col-6 col-lg-3 label-slot">
        <FormCheckbox v-model="rdCheck" name="rd-align-d" label="Purchased" />
      </div>
    </div>
    <p class="text-muted">
      Invalid, using the same component the Error States section below renders
      in today's treatment — so the two are the same controls, failing the same
      rules, side by side.
    </p>
    <ErrorStates />
  </div>

  <Heading :level="HeadingLevelEnum.H2">Slider</Heading>
  <p>
    With a percentage tooltip and quarter marks, and a stepped variant with a
    mark per stop.
  </p>
  <div class="row">
    <div class="col-12 col-md-6">
      <Slider
        v-model="sliderValue"
        :marks="sliderMarks"
        :tooltip-formatter="sliderTooltip"
        process
      />
      <p class="text-muted">Value: {{ sliderValue }}</p>
    </div>
    <div class="col-12 col-md-6">
      <Slider
        v-model="sliderStepped"
        :min="0"
        :max="8"
        :interval="1"
        :marks="powerMarks"
        :dot-size="14"
      />
      <p class="text-muted">Pips: {{ sliderStepped }}</p>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Toggle</Heading>
  <p>
    The standalone switch — not a form field, it just emits
    <code>toggle</code>.
  </p>
  <div class="row">
    <div class="col-12">
      <Toggle :active="toggleActive" label="Active" @toggle="toggleTheToggle" />
      <Toggle :active="false" label="Inactive" @toggle="toggleTheToggle" />
      <Toggle
        :active="toggleActive"
        :loading="toggleLoading"
        label="Loading"
        @toggle="fireToggleLoading"
      />
      <Toggle :active="toggleActive" label="Disabled" disabled />
      <Toggle :active="toggleActive" label="Inline" inline />
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Error States</Heading>
  <p>
    Fields validated on mount, so the invalid styling shows without interaction.
    The message itself lives in each field's tooltip.
  </p>
  <ErrorStates />

  <Heading :level="HeadingLevelEnum.H2">FormActions</Heading>
  <p>
    The submit/cancel footer. Submitting spins the save button; when
    <code>dirty</code> is set, cancel asks for confirmation first.
  </p>
  <form id="visual-tests-form" @submit.prevent="onSubmit">
    <FormActions
      form-id="visual-tests-form"
      :submitting="submitting"
      dirty
      @cancel="onCancel"
    />
  </form>
  <form id="visual-tests-form-no-cancel" @submit.prevent="onSubmit">
    <FormActions
      form-id="visual-tests-form-no-cancel"
      :submitting="submitting"
      hide-cancel
    />
  </form>
</template>

<!--
  What is left of the preview: the message line, which needs an element the
  components do not emit yet, and the label slot, which needs a prop they do not
  have. Everything else has moved into the components — which is why the controls
  above this section look like this too.

  Deliberately unscoped and deliberately in this page; it reaches nothing else.
  The wrapper class is doubled to win specificity against the components' own
  scoped rules, which carry a [data-v-*] attribute.
-->
<style lang="scss">
.form-redesign.form-redesign {
  /*
   * A checkbox or toggle renders its message as a bare text node right after the
   * label, with no element and nothing between them -- which is why it reads as
   * "Accept termsThe terms field is required". Only the gap and the colours are
   * reachable from here, so the container is coloured and the label put back.
   *
   * Giving it a real element, and tying it to the input with aria-describedby,
   * is phase 3.
   */
  .base-checkbox--with-error,
  .form-toggle--with-error {
    gap: 8px;
    color: var(--color-danger, #dc3545);
  }

  .base-checkbox--with-error label,
  .form-toggle--with-error label {
    color: var(--color-text, #c8c8c8);
  }

  /*
   * What a message would look like, on markup the components do not yet emit.
   * line-height is set so the reserved height below can equal it: inherited it
   * was 21px against a reserved 20px, so the field underneath still moved by a
   * pixel -- which is exactly what reserving the line prevents.
   */
  .field-message {
    margin: -12px 0 15px;
    font-size: 0.875rem;
    line-height: 1.25rem;
    color: var(--color-danger, #dc3545);
  }

  /* The line is always there and merely empties, so nothing below it moves.
     Exactly one line-height -- a rounder number would move the page again. */
  .field-message--reserved {
    min-height: 1.25rem;
  }

  /*
   * A field starts below its label; a checkbox starts at the top of the row,
   * because it has no label above it. FormInput, FormTextarea and RadioList all
   * have one; FormCheckbox and FormToggle are the two that never got one.
   *
   * Reserving the line is the demonstration, not the fix -- see D7.
   */
  .label-slot .base-checkbox,
  .label-slot .form-toggle {
    margin-top: calc(1.42857em + 5px);
    min-height: var(--field-h, 43px);
    align-items: center;
  }
}
</style>
