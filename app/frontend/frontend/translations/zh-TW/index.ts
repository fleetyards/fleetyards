import { messages as validationMessages } from "vee-validate/dist/locale/zh_TW.json";
import main from "./main";
import actions from "./actions";
import headlines from "./headlines";
import labels from "./labels";
import messages from "./messages";
import nav from "./nav";
import placeholders from "./placeholders";
import sublines from "./sublines";
import texts from "./texts";
import title from "./title";
import privacySettings from "./privacySettings";
import validationError from "./validationError";

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
