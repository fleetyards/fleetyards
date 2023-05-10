import Vue from "vue";

const Bus = new Vue();

export const useComlink = (): typeof Bus => Bus;
