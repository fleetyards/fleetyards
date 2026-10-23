// The build never polyfills built-ins, and engines that parse our bundle can
// still lack these (Chrome < 97, Safari < 15.4).
import "core-js/actual/array/at";
import "core-js/actual/array/find-last";
import "core-js/actual/object/has-own";
import "core-js/actual/string/at";
import "core-js/actual/string/replace-all";
