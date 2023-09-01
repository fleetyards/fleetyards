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
import datetime from "./datetime";
import number from "./number";
import paginator from "@/shared/components/Paginator/translations/en";
import baseBtn from "@/shared/components/base/Btn/translations/en";
import appModal from "@/shared/components/AppModal/translations/en";
import chart from "@/shared/components/Chart/translations/en";
import filteredList from "@/shared/components/FilteredList/translations/en";
import filteredTable from "@/shared/components/FilteredTable/translations/en";
import emptyBox from "@/shared/components/EmptyBox/translations/en";
import filterGroup from "@/shared/components/base/FilterGroup/translations/en";
import models from "@/shared/translations/en/models";
import validations from "@/shared/translations/en/validations";

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
  validation_error: validationError,
  datetime,
  number,
  validations: validations,
  ...paginator,
  ...baseBtn,
  ...appModal,
  ...chart,
  ...filteredList,
  ...filteredTable,
  ...emptyBox,
  ...filterGroup,
  ...models,
};
