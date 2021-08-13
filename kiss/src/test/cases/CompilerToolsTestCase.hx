package test.cases;

import utest.Assert;
import utest.Test;
import kiss.CompilerTools;
import kiss.Prelude;
#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
#end

class CompilerToolsTestCase extends Test {
    // Skip these tests on C# for now because they will fail due to this haxe bug:
    // https://github.com/HaxeFoundation/haxe/issues/10332
    #if ((sys || hxnodejs) && !cs)
    function testCompileHelloWorldJs() {
        Assert.equals("Hello world!", _testCompileHelloWorldJs()().trim());
        Assert.equals("Hello world!", _testCompileHelloWorldJsWithPackageJson()().trim());
    }

    static macro function _testCompileHelloWorldJs() {
        return CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", JavaScript, {
                outputFolder: "bin/helloWorldJsTest",
            });
    }

    static macro function _testCompileHelloWorldJsWithPackageJson() {
        return CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", JavaScript, {
                outputFolder: "bin/helloWorldJsTestWithPackageJson",
                langProjectFile: "kiss/src/test/files/package.json"
            });
    }

    function testCompileHelloWorldPy() {
        Assert.equals("Hello world!", _testCompileHelloWorldPy()().trim());
        Assert.equals("Hello world!", _testCompileHelloWorldPyWithRequirementsTxt()().trim());
        Assert.equals("Hello world!", _testCompileHelloWorldPyWithSetupPy()().trim());
    }

    static macro function _testCompileHelloWorldPy() {
        return CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", Python, {
                outputFolder: "bin/helloWorldPyTest",
            });
    }

    static macro function _testCompileHelloWorldPyWithRequirementsTxt() {
        return CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", Python, {
                outputFolder: "bin/helloWorldPyTestWithRequirementsTxt",
                langProjectFile: "kiss/src/test/files/requirements.txt"
            });
    }

    static macro function _testCompileHelloWorldPyWithSetupPy() {
        return CompilerTools.compileFileToScript(
            "kiss/template/src/template/Main.kiss", Python, {
                outputFolder: "bin/helloWorldPyTestWithSetupPy",
                langProjectFile: "kiss/src/test/files/setup.py"
            });
    }

    // TODO test what happens when passing more arguments/files
    #end
}
