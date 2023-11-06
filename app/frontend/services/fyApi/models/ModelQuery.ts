/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

import type { ModelSortEnum } from './ModelSortEnum';

export type ModelQuery = {
    beamGteq?: number;
    beamLteq?: number;
    classificationIn?: Array<string>;
    descriptionCont?: string;
    focusIn?: Array<string>;
    heightGteq?: number;
    heightLteq?: number;
    idIn?: Array<string>;
    idNotIn?: Array<string>;
    lengthGteq?: number;
    lengthLteq?: number;
    manufacturerIn?: Array<string>;
    nameCont?: string;
    nameEq?: string;
    slugEq?: string;
    nameIn?: Array<string>;
    nameOrDescriptionCont?: string;
    onSaleEq?: boolean;
    pledgePriceGteq?: number;
    pledgePriceLteq?: number;
    pledgePriceIn?: Array<number>;
    priceGteq?: number;
    priceLteq?: number;
    priceIn?: Array<number>;
    productionStatusIn?: Array<string>;
    searchCont?: string;
    sizeIn?: Array<string>;
    willItFit?: string;
    sorts?: (Array<ModelSortEnum> | ModelSortEnum);
};

