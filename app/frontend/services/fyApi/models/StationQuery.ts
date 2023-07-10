/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

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
    sorts?: Array<string>;
};

