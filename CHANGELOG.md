# Exfile Changelog

## v0.3.0

### Breaking Changes

* The backend configuration has changed from a list containing a module name and
	a map of options to a 2-element tuple containing a module name and a keyword
	list. See `config/test.exs` for an example of what the new configuration
	looks like.
