# Exfile Changelog

## v0.4

### Breaking Changes

* When a file is cast to an Ecto field, it will be uploaded to a cache backend.
	Because Ecto doesn't have callbacks, the step to save the files to the store
	backend has to be called manually. See the documentation of
	`Exfile.Ecto.prepare_uploads/2` for more details.
* The Exfile URI of a file, specifying both the backend and file ID, is now stored
	in the Ecto field. Exfile recognizes vanilla file IDs, but this may be 
	removed by v1.0. (An Exfile URI looks like `exfile://[backend name]/[file id]`)

## v0.3.3

### Enhancements

* Configurable timeout for refreshing backends (default is still 5 seconds)
* Implement TTL option for files in a FileSystem backend

## v0.3.2

### Bug fixes

* Relax Plug dependency constraint from `~> 1.0.0` to `~> 1.0`

## v0.3.1

### Bug fixes

* Fix `(CompileError) module Phoenix.HTML.Safe is not loaded and could not be
	found` when `phoenix_html` was not listed as a dependency.

## v0.3.0

### Enhancements

* `ecto` and `phoenix_html` are now optional dependencies

### Breaking Changes

* The backend configuration has changed from a list containing a module name and
	a map of options to a 2-element tuple containing a module name and a keyword
	list. See `config/test.exs` for an example of what the new configuration
	looks like.
