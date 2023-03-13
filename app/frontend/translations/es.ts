import { messages as validationMessages } from "vee-validate/dist/locale/es.json";
import main from "./es/index";
import actions from "./es/actions";
import headlines from "./es/headlines";
import labels from "./es/labels";
import messages from "./es/messages";
import nav from "./es/nav";
import placeholders from "./es/placeholders";
import sublines from "./es/sublines";
import texts from "./es/texts";
import title from "./es/title";
import privacySettings from "./es/privacySettings";
import validationError from "./es/validationError";

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
