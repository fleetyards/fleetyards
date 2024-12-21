/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { StationSortEnum } from './StationSortEnum';
export type StationQuery = {
    searchCont?: string;
    nameCont?: string;
    slugEq?: string;
    celestialObjectEq?: string;
    cargoHubEq?: boolean;
    refineryEq?: boolean;
    withShops?: boolean;
    habsNotNull?: boolean;
    commodityItemType?: string;
    nameIn?: Array<string>;
    celestialObjectIn?: Array<string>;
    starsystemIn?: Array<string>;
    stationTypeIn?: Array<string>;
    shopsShopTypeIn?: Array<string>;
    docksShipSizeIn?: Array<string>;
    sorts?: (Array<StationSortEnum> | StationSortEnum);
};

