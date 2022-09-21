import Noty from "noty";

declare interface FleetyardsNotyOptions extends Noty.Options {
  icon?: string;
  catergory?: string;
}

declare class FleetyardsNoty extends Noty {
  constructor(options?: FleetyardsNotyOptions);
}
