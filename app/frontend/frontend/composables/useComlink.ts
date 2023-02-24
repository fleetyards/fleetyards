import Vue from "vue";

const Bus = new Vue();

export default function useComlink(): typeof Bus {
  return Bus;
}
