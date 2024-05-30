/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Component } from './Component';
import type { Model } from './Model';
import type { ModelModule } from './ModelModule';
import type { ModelPaint } from './ModelPaint';
import type { SearchResultTypeEnum } from './SearchResultTypeEnum';
export type SearchResult = {
    id: string;
    type: SearchResultTypeEnum;
    item: (Model | Component | ModelModule | ModelPaint);
};

