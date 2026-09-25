import { FleetContractStateEnum } from "@/services/fyApi";

/*
 * The four boards, as one page's filter rather than four pages: they differ in
 * which contracts they ask for and in nothing else.
 *
 * The choice rides in the query rather than in the path, so each board can be
 * linked to *and* switching between them keeps the page. `App.vue` keys the
 * page on `locale-path`, so a fourth path would have thrown the whole view
 * away and rebuilt it on every switch.
 */
export type ContractBoardView = {
  key: string;
  states: FleetContractStateEnum[];
  mine: boolean;
  inHand: boolean;
  icon: string;
};

export const CONTRACT_BOARD_VIEWS: ContractBoardView[] = [
  {
    key: "open",
    // Everything still worth looking at. A draft is only visible to the people
    // who could publish it, which the API decides.
    states: [
      FleetContractStateEnum.DRAFT,
      FleetContractStateEnum.OPEN,
      FleetContractStateEnum.IN_PROGRESS,
    ],
    mine: false,
    inHand: false,
    icon: "fa-light fa-clipboard-list",
  },
  {
    key: "closed",
    // Everything the fleet is done with, however it ended.
    states: [
      FleetContractStateEnum.FULFILLED,
      FleetContractStateEnum.SETTLED,
      FleetContractStateEnum.CANCELLED,
      FleetContractStateEnum.EXPIRED,
    ],
    mine: false,
    inHand: false,
    icon: "fa-light fa-box-archive",
  },
  {
    key: "mine",
    // The work in hand: a claimed contract, or an expired one whose deliveries
    // are still waiting for an answer -- the API drops the settled ones.
    states: [
      FleetContractStateEnum.IN_PROGRESS,
      FleetContractStateEnum.EXPIRED,
    ],
    mine: true,
    inHand: true,
    icon: "fa-light fa-user-helmet-safety",
  },
  {
    key: "completed",
    // Finished work only. A cancelled or expired contract is not something the
    // reader completed.
    states: [FleetContractStateEnum.FULFILLED, FleetContractStateEnum.SETTLED],
    mine: true,
    inHand: false,
    icon: "fa-light fa-circle-check",
  },
];

export const DEFAULT_CONTRACT_BOARD_VIEW = CONTRACT_BOARD_VIEWS[0];

// `route.query` hands back a string, an array of them, or nothing, and none of
// the three may leave the board asking for nothing at all.
export const contractBoardViewFrom = (value: unknown): ContractBoardView =>
  CONTRACT_BOARD_VIEWS.find((view) => view.key === value) ??
  DEFAULT_CONTRACT_BOARD_VIEW;
