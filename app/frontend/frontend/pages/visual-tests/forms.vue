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
    Form controls — proposed language
  </Heading>
  <p>
    A proposal to look at, not a component change: the CSS below lives in this
    page and reaches nothing else. Everything above this heading is what ships
    today, so scroll up to compare.
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
  Preview scaffolding for the proposed form language, deliberately unscoped and
  deliberately in this page: it applies while this page is open and reaches
  nothing else in the app. If the language is adopted it moves into the
  components and this block goes.

  The wrapper class is doubled to win specificity against the components' own
  scoped rules, which carry a [data-v-*] attribute.
-->
<style lang="scss">
.form-redesign.form-redesign {
  /* ---------- the box ---------- */

  /*
   * The frame lives on the wrapper, not the field. An <input> is a replaced
   * element and renders no pseudo-elements, so a cap cannot sit on it -- and
   * moving the frame out here makes prefix, field and suffix one control rather
   * than three boxes that have to pretend to be one.
   */
  .base-input__wrapper,
  .base-textarea__wrapper {
    position: relative;
    background-color: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
    border-radius: var(--radius-control, 8px);
    box-shadow: none;
  }

  /* The field itself carries nothing now. */
  .base-input input,
  .base-textarea textarea,
  .base-input__prefix,
  .base-input__suffix {
    background-color: transparent;
    background-image: none;
    border: none;
    border-radius: 0;
    box-shadow: none;
  }

  .base-input__prefix,
  .base-input__suffix {
    color: var(--color-endcap, #7a8288);
  }

  /*
   * Hover lifts the fill, on the token Btn already uses for exactly this. Not on
   * a checked radio or toggle, whose fill is the state -- there the signature is
   * doing the talking and the surface should stay out of it.
   */
  .base-input__wrapper:hover,
  .base-textarea__wrapper:hover,
  .base-checkbox input:not(:disabled):hover + label::before,
  .radio-list__item
    input[type="radio"]:not(:disabled):not(:checked):hover
    + label::before,
  .form-toggle
    input:not(:disabled):not(:checked):hover
    + label
    .form-toggle-switch {
    background-color: var(--color-control-hover, rgb(52 58 64 / 0.95));
  }

  /* Brighter than the $input-placerholder it replaces, which was mixed for a
     lighter fill and disappears into this one. */
  .base-input input::placeholder,
  .base-textarea textarea::placeholder {
    color: var(--color-endcap, #7a8288);
  }

  /* ---------- the cap carries the state ---------- */

  .base-input__wrapper::before,
  .base-input__wrapper::after,
  .base-textarea__wrapper::before,
  .base-textarea__wrapper::after {
    position: absolute;
    right: max(10px, var(--cap-inset, 12%));
    left: max(10px, var(--cap-inset, 12%));
    height: var(--cap-h-btn, 2px);
    background-color: var(--field-cap, var(--color-endcap, #7a8288));
    border-radius: var(--cap-r-btn, 1px);
    content: "";
    transition: background-color 0.15s ease;
  }

  .base-input__wrapper::before,
  .base-textarea__wrapper::before {
    top: -1px;
  }

  .base-input__wrapper::after,
  .base-textarea__wrapper::after {
    bottom: -1px;
  }

  /*
   * A field's cap carries what its edge carries elsewhere: neutral at rest,
   * primary on focus. Same rule as the boxes you tick, different carrier --
   * an <input> is a replaced element and cannot draw one, so the wrapper does.
   *
   * Focus was invisible on every input in the app before this: `outline: none`
   * with nothing put in its place, at 374 call sites, both password fields
   * included.
   */
  .base-input--with-error,
  .base-textarea--with-error {
    --field-cap: var(--color-danger, #dc3545);
  }

  /* Declared after the error tone on purpose: while a field is focused, focus is
     the more useful thing to show. The error is still there when you leave. */
  .base-input:focus-within,
  .base-textarea:focus-within {
    --field-cap: var(--color-primary, #428bca);
  }

  .base-input--disabled {
    --field-cap: transparent;

    opacity: 0.5;
  }

  /* ---------- boxes you tick ---------- */

  /*
   * background-clip matters here, and it is not cosmetic. --color-edge is
   * translucent and a background is painted under the border by default, so the
   * edge composites over whatever fills the box. The radio's dot is made by
   * filling the box primary and punching a ring back out of it with an inset
   * shadow -- and an inset shadow stops at the padding box, so the blue stayed
   * under the border and read as a primary edge on the chosen radio.
   *
   * Clipping the fill to the padding box keeps the edge composited over the page
   * in every state, so it looks the same whatever is inside.
   */
  .base-checkbox input + label::before,
  .radio-list__item input[type="radio"] + label::before {
    background-color: var(--color-control, rgb(39 43 48 / 0.9));
    background-clip: padding-box;
    border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
    border-radius: var(--radius-control-bare, 6px);
  }

  .radio-list__item input[type="radio"] + label::before {
    border-radius: 50%;
  }

  /*
   * The whole fix for a radio nobody could reach: `display: none` takes it out
   * of the tab order, which is why the :focus rule three lines below it in the
   * component has never once fired. FormCheckbox already does it this way.
   */
  .radio-list__item input[type="radio"] {
    display: inline-block;
    position: absolute;
    opacity: 0;
  }

  /*
   * The control's own edge carries focus, at the width it already has -- no ring
   * around it and no thickening.
   *
   * This only works because checked stopped touching the edge. While both used
   * primary, focus on an already-checked control was invisible, and tabbing into
   * a radio group lands on exactly that one.
   */
  /*
   * Checked is the dot, and only the dot -- the edge stays neutral, so that
   * primary on an edge means one thing anywhere in a form: this is focused.
   *
   * The dot is a primary fill with a ring punched back out of it by an inset
   * shadow in the surrounding colour. That colour was $input-bg, so it has to
   * follow the new fill or the ring is drawn in the old one.
   */
  .radio-list__item input[type="radio"]:checked + label::before {
    background-color: var(--color-primary, #428bca);
    box-shadow: inset 0 0 0 4px var(--color-control, rgb(39 43 48 / 0.9));
  }

  /*
   * The components answer :focus; this language answers :focus-visible. That gap
   * is the whole bug behind three reports in a row: a mouse click leaves the
   * control focused, so their rules kept firing when nothing looked focused any
   * more -- a primary edge that stayed on the radio you had just clicked, and an
   * inset primary ring that stacked on the edge below and read as a 2px focus.
   *
   * Expressed as `:focus:not(:focus-visible)` rather than as a reset on :focus
   * with the highlight re-applied after it. The first attempt did the latter and
   * put out the focus entirely: the reset had to name :checked to keep the
   * radio's dot, which made it one pseudo-class more specific than the
   * :focus-visible rule meant to override it -- so the checked control, the one
   * a keyboard actually lands on, lost its highlight.
   */
  .base-checkbox input:focus:not(:focus-visible) + label::before,
  .radio-list__item
    input[type="radio"]:focus:not(:focus-visible)
    + label::before,
  .form-toggle input:focus:not(:focus-visible) + label .form-toggle-switch {
    border-color: var(--color-edge, rgb(122 130 136 / 0.5));
    box-shadow: none;
  }

  /* The dot is an inset shadow, so it has to survive that reset. */
  .radio-list__item
    input[type="radio"]:checked:focus:not(:focus-visible)
    + label::before {
    box-shadow: inset 0 0 0 4px var(--color-control, rgb(39 43 48 / 0.9));
  }

  /* Keyboard focus: the edge lights up, and nothing else moves. */
  .base-checkbox input:focus-visible + label::before,
  .base-checkbox input:checked:focus-visible + label::before,
  .radio-list__item input[type="radio"]:focus-visible + label::before,
  .form-toggle input:focus-visible + label .form-toggle-switch {
    border-color: var(--color-primary, #428bca);
    box-shadow: none;
  }

  .radio-list__item input[type="radio"]:checked:focus-visible + label::before {
    border-color: var(--color-primary, #428bca);
    box-shadow: inset 0 0 0 4px var(--color-control, rgb(39 43 48 / 0.9));
  }

  /*
   * Error rides the same signature as focus, and loses to it while the control
   * is focused -- the field's cap does exactly this, one carrier per control.
   *
   * RadioList is absent because it has none: it never calls useField, so a form
   * has no way to mark it invalid. That is a gap in the component, not in the
   * language.
   */
  .base-checkbox--with-error input + label::before {
    border-color: var(--color-danger, #dc3545);
  }

  .form-toggle--with-error input + label .form-toggle-switch {
    border-color: var(--color-danger, #dc3545);
  }

  /* Disabled says nothing at all: the signature goes quiet rather than neutral,
     so a disabled control cannot be mistaken for a resting one. */
  .base-checkbox input:disabled + label::before,
  .radio-list__item input[type="radio"]:disabled + label::before,
  .form-toggle input:disabled + label .form-toggle-switch {
    border-color: var(--color-edge-faint, rgb(122 130 136 / 0.16));
  }

  /* ---------- the toggle ---------- */

  /*
   * Only the resting colours and the focus edge. A toggle's filled track is the
   * conventional "on", and unlike a checkbox it has nothing inside it that a
   * fill could hide -- so it keeps flooding primary when it is on, where the
   * checkbox marks state on its edge to keep the tick legible.
   */
  .form-toggle input + label .form-toggle-switch {
    background: var(--color-control, rgb(39 43 48 / 0.9));
    border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  }

  /* On is the flooded track. Its edge stays neutral too. */
  .form-toggle input:checked + label .form-toggle-switch {
    background: var(--color-primary, #428bca);
  }
}
</style>
