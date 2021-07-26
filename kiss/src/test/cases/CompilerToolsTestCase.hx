package test.cases;

import utest.Assert;
import utest.Test;
import kiss.CompilerTools;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class CompilerToolsTestCase extends Test {
    function testCompileHelloWorld() {
        Assert.equals("Hello, world!", _testCompileHelloWorld());
    }

    static macro function _testCompileHelloWorld() {
        var runHelloWorld = CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", {
                lang: JavaScript,
                outputFolder: "bin/js",
            });

        return {
            pos: Context.currentPos(),
            expr: EConst(CString(runHelloWorld(), DoubleQuotes))
        };
    }
}
