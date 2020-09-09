# working_set

Companion to your editor that makes searching, and using search results for
jumping around, super nice.

[![Working Set Demo](https://github.com/coderifous/working_set/blob/master/assets/video.png)](https://vimeo.com/455633260)

## Installation

Installing the gem adds the working_set command to your path.

    $ gem install working_set

Working Set uses `ag` "the silver searcher" for super fast searching power:

    $ brew install ag

Install the plugin for your editor.

* [Vim Plugin](https://github.com/coderifous/working-set.vim)

Note: Currently there's only a plugin for Vim, however Working Set will be
compatible with any editor that can be extended and communicate via socket.

## Usage

Run the working_set command in your project's directory.

    $ cd my-project
    $ working_set

working_set is now running, listening on a file socket, ready to receive
commands from your text editor which you should run in a separate terminal but
in the same directory.

    $ cd my-project
    $ vim

## Options

Run `working_set -h` to see a list of command line options:

    --watch | -w

      Tells working_set to monitor the filesystem for changes and refresh the
      search results automatically when changes are detected.  The value should be
      point at the directory you want to monitor.

      Example: --watch=app

      Default: none, search results will not automatically refresh.

    --context | -c

      Sets number of contextual lines to show around matches.

      Example: --count=3

      Default: 1

    --socket | -s

      Sets the path for the socket file to create.

      Example: --socket=/tmp/my-special-project

      Default: .working_set_socket

    --help | -h

      Show help.

## Commands in working_set

You can press '?' in working_set to see key bindings:

    ?          - display help
    q          - quit
    j          - select next match
    k          - select previous match
    ctrl-n     - select first match in next file
    ctrl-p     - select first match in previous file
    enter      - Tell editor to jump to match
    down arrow - scroll down without changing selection
    up arrow   - scroll up without changing selection
    r          - refresh search results
    [          - decrease context lines
    ]          - increase context lines
    z          - toggle showing match lines vs just matched files
    y          - copy selected match to system clipboard
    Y          - copy selected match + context to system clipboard

## Todo
* Add support for searching straight from working_set using "/" key.
* Add support for setting search argument prefix as working_set command argument.
  e.g. --prefix="--ignore=tmp,vendor"
* Add support for bookmarks.
* Add support for search history.
* Add support for customizing key bindings.
* Document adapter so other search tools can be used.

## API for Editor Integration

Information for integrating Working Set with your editor can be found
[here](https://github.com/coderifous/working_set/blob/master/API_FOR_EDITOR_INTEGRATION.md).

## Development

1) Fork the repo, clone the source code.
2) run `bundle install` to install dependencies.
3) run `bin/working_set -d` to execute the program with debug logging enabled
4) watch the debug messages: `tail -f working_set.log`
5) make code changes, restart `working_set` to see their effect.

Please do submit pull requests to add features, fix bugs, etc. Please discuss
before spending lots of time on large changes.

