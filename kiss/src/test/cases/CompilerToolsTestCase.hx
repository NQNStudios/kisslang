package test.cases;

import utest.Assert;
import utest.Test;
import kiss.CompilerTools;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class CompilerToolsTestCase extends Test {
    function testCompileHelloWorldJs() {
        Assert.equals("Hello world!", _testCompileHelloWorldJs());
    }

    static macro function _testCompileHelloWorldJs() {
        var runHelloWorld = CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", {
                lang: JavaScript,
                outputFolder: "bin/helloWorldJsTest",
            });

        return {
            pos: Context.currentPos(),
            expr: EConst(CString(runHelloWorld(), DoubleQuotes))
        };
    }

    function testCompileHelloWorldPy() {
        Assert.equals("Hello world!", _testCompileHelloWorldPy());
    }

    static macro function _testCompileHelloWorldPy() {
        var runHelloWorld = CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", {
                lang: Python,
                outputFolder: "bin/helloWorldPyTest",
            });

        return {
            pos: Context.currentPos(),
            expr: EConst(CString(runHelloWorld(), DoubleQuotes))
        };
    }



    // TODO test what happens when passing more arguments/files
}
