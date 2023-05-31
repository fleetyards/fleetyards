import { messages as validationMessages } from "vee-validate/dist/locale/fr.json";

import actions from "./fr/actions";
import headlines from "./fr/headlines";
import main from "./fr/index";
import labels from "./fr/labels";
import messages from "./fr/messages";
import nav from "./fr/nav";
import placeholders from "./fr/placeholders";
import privacySettings from "./fr/privacySettings";
import sublines from "./fr/sublines";
import texts from "./fr/texts";
import title from "./fr/title";
import validationError from "./fr/validationError";

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
