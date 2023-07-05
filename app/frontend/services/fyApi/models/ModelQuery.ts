/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */

export type ModelQuery = {
    beamGteq?: number | null;
    beamLteq?: number | null;
    classificationIn?: Array<string> | null;
    descriptionCont?: string | null;
    focus_in?: Array<string> | null;
    heightGteq?: number | null;
    heightLteq?: number | null;
    idIn?: Array<string> | null;
    idNotIn?: Array<string> | null;
    lengthGteq?: number | null;
    lengthLteq?: number | null;
    manufacturerIn?: Array<string> | null;
    nameCont?: string | null;
    nameIn?: Array<string> | null;
    nameOrDescriptionCont?: string | null;
    onSaleEq?: boolean | null;
    pledgePriceGteq?: number | null;
    pledgePriceLteq?: number | null;
    pledge_price_in?: Array<number> | null;
    priceGteq?: number | null;
    priceLteq?: number | null;
    price_in?: Array<number> | null;
    production_status_in?: Array<string> | null;
    searchCont?: string | null;
    size_in?: Array<string> | null;
    sorts?: (Array<string> | string) | null;
    willItFit?: string | null;
};

