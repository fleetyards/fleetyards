import main from "./main";
import actions from "./actions";
import labels from "./labels";
import placeholders from "./placeholders";
import paginator from "@/shared/components/Paginator/translations/en";
import baseBtn from "@/shared/components/BaseBtn/translations/en";
import appModal from "@/shared/components/AppModal/translations/en";
import chart from "@/shared/components/Chart/translations/en";
import filteredList from "@/shared/components/FilteredList/translations/en";
import filteredTable from "@/shared/components/FilteredTable/translations/en";
import emptyBox from "@/shared/components/EmptyBox/translations/en";
import filterGroup from "@/shared/components/Form/FilterGroup/translations/en";
import models from "@/shared/translations/en/models";

export default {
  ...main,
  labels,
  placeholders,
  actions,
  ...paginator,
  ...baseBtn,
  ...appModal,
  ...chart,
  ...filteredList,
  ...filteredTable,
  ...emptyBox,
  ...filterGroup,
  models,
};
