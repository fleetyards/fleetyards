/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ItemPriceItemTypeEnum } from './ItemPriceItemTypeEnum';
import type { ItemPriceTypeEnum } from './ItemPriceTypeEnum';
export type ItemPriceQuery = {
    locationCont?: string;
    itemIdEq?: string;
    itemIdIn?: Array<string>;
    itemTypeEq?: ItemPriceItemTypeEnum;
    itemTypeIn?: Array<ItemPriceItemTypeEnum>;
    priceTypeEq?: ItemPriceTypeEnum;
    priceTypeIn?: Array<ItemPriceTypeEnum>;
};

