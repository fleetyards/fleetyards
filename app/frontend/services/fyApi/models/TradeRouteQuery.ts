/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CommodityTypeEnum } from './CommodityTypeEnum';
import type { TradeRouteSortEnum } from './TradeRouteSortEnum';
export type TradeRouteQuery = {
    cargoShip?: string;
    originStationIn?: Array<string>;
    destinationStationIn?: Array<string>;
    originCelestialObjectIn?: Array<string>;
    destinationCelestialObjectIn?: Array<string>;
    originStarsystemIn?: Array<string>;
    destinationStarsystemIn?: Array<string>;
    commodityIn?: Array<string>;
    commodityTypeIn?: Array<CommodityTypeEnum>;
    commodityTypeNotIn?: Array<CommodityTypeEnum>;
    sorts?: (Array<TradeRouteSortEnum> | TradeRouteSortEnum);
};

