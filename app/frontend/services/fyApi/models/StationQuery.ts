/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

export type StationQuery = {
    searchCont?: string | null;
    nameCont?: string | null;
    slugEq?: string | null;
    celestialObjectEq?: string | null;
    cargoHubEq?: boolean | null;
    refineryEq?: boolean | null;
    withShops?: boolean | null;
    habsNotNull?: boolean | null;
    commodityItemType?: string | null;
    nameIn?: Array<string> | null;
    celestialObjectIn?: Array<string> | null;
    starsystemIn?: Array<string> | null;
    stationTypeIn?: Array<string> | null;
    shopsShopTypeIn?: Array<string> | null;
    docksShipSizeIn?: Array<string> | null;
    sorts?: Array<string> | null;
};

