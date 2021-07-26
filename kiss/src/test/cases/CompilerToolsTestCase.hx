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
        Assert.equals("Hello world!", _testCompileHelloWorldJs()());
    }

    static macro function _testCompileHelloWorldJs() {
        return CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", {
                lang: JavaScript,
                outputFolder: "bin/helloWorldJsTest",
            });
    }

    function testCompileHelloWorldPy() {
        Assert.equals("Hello world!", _testCompileHelloWorldPy()());
    }

    static macro function _testCompileHelloWorldPy() {
        return CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", {
                lang: Python,
                outputFolder: "bin/helloWorldPyTest",
            });
    }

    // TODO test what happens when passing more arguments/files
}
