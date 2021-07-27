package test.cases;

import utest.Assert;
import utest.Test;
import kiss.CompilerTools;
import kiss.Prelude;

@:build(kiss.Kiss.build())
class ExternTestCase extends Test {
    // Skip these tests on C# for now because they will fail due to this haxe bug:
    // https://github.com/HaxeFoundation/haxe/issues/10332
    #if ((sys || hxnodejs) && !cs)
    function testExternPython() {
        _testExternPython();
    }

    function testExternJavaScript() {
        _testExternJavaScript();
    }
    #end
}
