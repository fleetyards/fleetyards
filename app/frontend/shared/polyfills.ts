// The build adds no polyfills, and older engines can parse the chunks they
// load yet lack these built-ins (Chrome < 98, Safari < 15.4). The date picker
// dependency calls structuredClone.
import "core-js/actual/array/at";
import "core-js/actual/array/find-last";
import "core-js/actual/object/has-own";
import "core-js/actual/string/at";
import "core-js/actual/string/replace-all";
import "core-js/actual/structured-clone";
