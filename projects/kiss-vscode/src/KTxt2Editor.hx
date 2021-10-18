import EditorExterns;

class KTxt2Editor {
    public static function main() {
        var vscode = EditorExterns.acquireVsCodeApi();

        var document = EditorExterns.window.document;
        var pElement = document.createElement("p");
        pElement.innerHTML = "helly eah";
        document.body.appendChild(pElement);
    }
}
