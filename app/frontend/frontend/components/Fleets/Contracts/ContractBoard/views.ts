import { FleetContractStateEnum } from "@/services/fyApi";

/*
 * The four boards, as one page's filter rather than four pages: they differ in
 * which contracts they ask for and in nothing else. Each is a route of its own
 * so it can be linked to -- the same shape the logistics ledger and the
 * transfers list use, where one component answers to several route names.
 */
export type ContractBoardView = {
  key: string;
  route: string;
  states: FleetContractStateEnum[];
  mine: boolean;
  icon: string;
};

export const CONTRACT_BOARD_VIEWS: ContractBoardView[] = [
  {
    key: "open",
    route: "fleet-contracts",
    // Everything still worth looking at. A draft is only visible to the people
    // who could publish it, which the API decides.
    states: [
      FleetContractStateEnum.DRAFT,
      FleetContractStateEnum.OPEN,
      FleetContractStateEnum.IN_PROGRESS,
    ],
    mine: false,
    icon: "fa-light fa-clipboard-list",
  },
  {
    key: "closed",
    route: "fleet-contracts-closed",
    // Everything the fleet is done with, however it ended.
    states: [
      FleetContractStateEnum.FULFILLED,
      FleetContractStateEnum.CANCELLED,
      FleetContractStateEnum.EXPIRED,
    ],
    mine: false,
    icon: "fa-light fa-box-archive",
  },
  {
    key: "mine",
    route: "fleet-contracts-mine",
    // The work in hand: a contract is claimed before anybody can deliver
    // against it, so there is one state a job being worked can be in.
    states: [FleetContractStateEnum.IN_PROGRESS],
    mine: true,
    icon: "fa-light fa-user-helmet-safety",
  },
  {
    key: "completed",
    route: "fleet-contracts-completed",
    // Finished work only. A cancelled or expired contract is not something the
    // reader completed.
    states: [FleetContractStateEnum.FULFILLED],
    mine: true,
    icon: "fa-light fa-circle-check",
  },
];

export const DEFAULT_CONTRACT_BOARD_VIEW = CONTRACT_BOARD_VIEWS[0];

// A route this page does not answer to must not leave the board asking for
// nothing at all.
export const contractBoardViewFrom = (name: unknown): ContractBoardView =>
  CONTRACT_BOARD_VIEWS.find((view) => view.route === name) ??
  DEFAULT_CONTRACT_BOARD_VIEW;
