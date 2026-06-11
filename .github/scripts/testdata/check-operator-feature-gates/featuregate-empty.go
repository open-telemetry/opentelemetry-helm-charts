// A source file with no gate registrations. The checker must treat an empty
// parse result as a failure rather than reporting "in sync", since it usually
// means the upstream file moved or its format changed.
package featuregate
