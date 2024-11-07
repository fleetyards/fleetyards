/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { VehicleSortEnum } from './VehicleSortEnum';
export type VehicleQuery = {
    searchCont?: string;
    idEq?: string;
    idIn?: Array<string>;
    idNotIn?: Array<string>;
    nameCont?: string;
    nameIn?: Array<string>;
    userUsernameIn?: Array<string>;
    modelSlugIn?: Array<string>;
    manufacturerIn?: Array<string>;
    modelIdEq?: string;
    modelIdIn?: Array<string>;
    modelIdNotIn?: Array<string>;
    modelNameCont?: string;
    modelNameIn?: Array<string>;
    modelProductionStatusIn?: Array<string>;
    modelSearchCont?: string;
    loanerEq?: boolean;
    wantedEq?: boolean;
    sorts?: (Array<VehicleSortEnum> | VehicleSortEnum);
};

