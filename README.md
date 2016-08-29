# working_set

Companion to your editor that makes searching, and using search results for
jumping around, super nice.

## Installation

Installing the gem adds the working_set command to your path.

    $ gem install working_set

## Usage

Run the working_set command in your project's directory.

    $ cd my-project
    $ working_set

working_set is now running, listening on a file socket, ready to receive
commands from your text editor which you should run in a separate terminal but
in the same directory.

    $ cd my-project
    $ vim

Currently only a vim plugin for working_set exists.  Install that plugin.  Read
it's docs.

## Options

Modify the behavior of working_set with these flags:

  --watch

    Tells working_set to monitor the filesystem for changes and refresh the
    search results automatically when changes are detected.  The value should be
    point at the directory you want to monitor.

    Example: --watch=src

    Default: none, search results will not automatically refresh.

  --socket | -S

    Sets the path for the socket file to create.

    Example: --socket=/tmp/my-special-project

    Default: .working_set_socket

## Commands in working_set

working_set command keys:

q      - quit working_set
r      - refresh search results
j      - move cursor to next match
k      - move cursor to previous match
ctrl+n - move cursor to next file
ctrl+p - move cursor to prev file
z      - fold search results to just show files
y      - copy currently selected line

Todo:
* Add support for searching straight from working_set using "/" key.
* Add support for setting search argument prefix as working_set command argument.
  e.g. --prefix="--ignore=tmp,vendor"
* Add help screen that shows commands.
* Add support for bookmarks.
* Add support for search history.
* Add support for customizing command keys.
* Document protocol so other plugin editors can exist.
* Document adapter so other search tools can be used.

## Development

1) Edit the source code.
   * uncomment bundler/setup in bin/working_set
2) run bin/working_set
3) test it out.

There's also some wierd support for a debugging messages over sockets:

Terminal 1:
  $ nc -l 8888

Terminal 2:
  $ bin/working_set --debug=8888
