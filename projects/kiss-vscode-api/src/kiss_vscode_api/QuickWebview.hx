package kiss_vscode_api;

import js.html.Document;
import js.node.Timers;
import JSDomExterns;

typedef QuickWebviewSetup = (Document) -> Void;
typedef QuickWebviewUpdate = (Document, Float, Function) -> Void;

@:build(kiss.Kiss.build())
class QuickWebview {}
