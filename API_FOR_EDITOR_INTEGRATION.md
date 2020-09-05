# API for Editor Integration

Most advanced text editors can be extended with plugins and other
customizations.  Working Set was built to be a companion to your text editor.
Since the original author of Working Set uses Vim, that's the first editor
integration that was created.

At time of writing, it's also the only one that exists.

Should someone wish to integrate another editor, e.g. Emacs, this is the
information they'd need to know.

## Overview

When `working_set` (WS) starts, it creates a socket file in the current
directory (named `.working_set_socket` by default). WS listens to the socket for
`message`s.  When it receives a `message`, it will asyncronously perform whatever
task is required, and then (possibly) send a `message` as a response to the
client via the socket file.

You can see a working client implementation in the [Vim
plugin](https://github.com/coderifous/working-set.vim).

## Message Format

Messages to Working Set are serialized JSON and have these keys:

    message: a single word, often a command

    args:    optional object, specific to a command.

    options: optional object, specific to a command.

Replies from Working Set will be similiar, always having a `message` key, but
additional keys may vary.

## Messages from Client to Server (Working Set)

#### search_changed

This message tells Working Set to update the search results.

Examples:

    { "message": "search_changed", "args": "foo" }

    { "message": "search_changed", "args": "foo", "options": { "whole_word": true } }

#### select_next_item, et al

This message tells Working Set to select the next item in the list.  There are a
few similar messages.

Example:

    { "message": "select_next_item" }

Similar messages:
* select_prev_item
* select_next_file
* select_prev_file

### tell_selected_item

Working Set will respond to this message with a "selected_item" message.

### tell_selected_item_content

Working Set will respond to this message with a "selected_item_content" message.

### show_match_lines_toggled

Working Set will toggle whether match lines are showed.

### refresh

Working Set will re-run the current search and update results.

## Messages from Server to Client (editor)

### selected_item

Example:

    { "message": "selected_item", "file_path": "app/foo.rb", "row": 1, "column": 10 }

Clients can do whatever they want when they recieve this message, one useful
response might be to jump to the specified file and location.

### selected_item_content

Example:

    { "message": "selected_item_content", data: "foo bar baz" }

Clients can do whatever they want when they recieve this message, one useful
response might be to insert the requested content where the user is typing.
