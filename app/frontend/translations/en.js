import { messages as validationMessages } from "vee-validate/dist/locale/en.json";
import main from "./en/index";
import actions from "./en/actions";
import headlines from "./en/headlines";
import labels from "./en/labels";
import messages from "./en/messages";
import nav from "./en/nav";
import placeholders from "./en/placeholders";
import sublines from "./en/sublines";
import texts from "./en/texts";
import title from "./en/title";
import privacySettings from "./en/privacySettings";
import validationError from "./en/validationError";

const validations = {};
Object.keys(validationMessages).forEach((key) => {
  validations[key] = validationMessages[key].replace(/\{/g, "%{");
});

export default {
  ...main,
  title,
  privacySettings,
  headlines,
  sublines,
  nav,
  labels,
  placeholders,
  actions,
  texts,
  messages,
  validations,
  validation_error: validationError,
};
