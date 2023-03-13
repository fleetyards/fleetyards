import { messages as validationMessages } from "vee-validate/dist/locale/de.json";
import main from "./de/index";
import actions from "./de/actions";
import headlines from "./de/headlines";
import labels from "./de/labels";
import messages from "./de/messages";
import nav from "./de/nav";
import placeholders from "./de/placeholders";
import sublines from "./de/sublines";
import texts from "./de/texts";
import title from "./de/title";
import privacySettings from "./de/privacySettings";
import validationError from "./de/validationError";

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
