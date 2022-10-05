`Context` doesn't have a local type building this way, so you'll have to pass the name from the `FrontendContext` instance to the `defaultKissState` function.

the `--macro KissFrontend.use()` declaration should be in a file called `extraParams.hxml` in the folder with `haxelib.json` and is automatically loaded by haxelib with `-lib kiss`. Seeing as you're not using it, `--macro kiss.Kiss.setup()` should probably go in there.`

This should be enough to build a `*.kiss` file anytime the compiler goes looking for an unknown type.

Imports are handled in the Frontend via `context.addImport`, where the `ImportMode` is

```haxe
enum ImportMode {
	INormal;//Represents a default import `import c`.
	IAsName(alias:String);//Represents the alias import `import c as alias`.
	IAll;//Represents the wildcard import `import *`.
}
```
