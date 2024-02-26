/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { FleetMembershipRoleEnum } from './FleetMembershipRoleEnum';
import type { FleetMembershipSortEnum } from './FleetMembershipSortEnum';
export type FleetMemberQuery = {
    usernameCont?: string;
    /**
     * Use usernameCont instead
     * @deprecated
     */
    nameCont?: string;
    roleIn?: Array<FleetMembershipRoleEnum>;
    sorts?: (Array<FleetMembershipSortEnum> | FleetMembershipSortEnum);
};

