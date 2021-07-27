package test.cases;

import utest.Assert;
import utest.Test;
import kiss.CompilerTools;
import kiss.Prelude;

@:build(kiss.Kiss.build())
class ExternTestCase extends Test {
    #if (sys || hxnodejs)
    function testExternPython() {
        _testExternPython();
    }

    function testExternJavaScript() {
        _testExternJavaScript();
    }
    #end
}
