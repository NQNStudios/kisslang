# duplicate-text-editor

Sometimes you have to edit text that will be duplicated in multiple files. For example,
when writing a tutorial which includes code snippets from an example project.

This VSCode extension lets you edit a text snippet simultaneously in every file where it occurs.

Like [LinkedEditingRanges](https://code.visualstudio.com/api/references/vscode-api#LinkedEditingRanges) but across multiple files and with no safety guarantees.

## Features

Attempts to be smart about cases where the snippet is indented differently in different files.

## Extension Settings

## Known Issues

Can't be used to de-indent a snippet.

## Release Notes