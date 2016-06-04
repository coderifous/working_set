# working_set

Companion to your editor that makes searching, and using search results for
jumping around, super nice.

## Installation

Installing the gem adds the working_set command to your path.

    $ gem install working_set

Then just run working_set from your project's root directory.

    $ cd my-project
    $ working_set

working_set is now running, listening on a socket, ready to receive commands
from your text editor which you should run in a separate terminal.

## Usage

Currently only a vim plugin exists.  Install that plugin.  Read it's stuff.

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
