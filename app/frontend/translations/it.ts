import { messages as validationMessages } from "vee-validate/dist/locale/it.json";
import main from "./it/index";
import actions from "./it/actions";
import headlines from "./it/headlines";
import labels from "./it/labels";
import messages from "./it/messages";
import nav from "./it/nav";
import placeholders from "./it/placeholders";
import sublines from "./it/sublines";
import texts from "./it/texts";
import title from "./it/title";
import privacySettings from "./it/privacySettings";
import validationError from "./it/validationError";

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
