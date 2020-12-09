package test.cases;

import utest.Test;
import utest.Assert;
import kiss.EmbeddedScript;
import kiss.Prelude;

class DSLTestCase extends Test {
    function testScript() {
        new DSLScript().run();
    }
}

@:build(kiss.EmbeddedScript.build("kiss/src/test/cases/DSL.kiss", "kiss/src/test/cases/DSLScript.dsl"))
class DSLScript extends EmbeddedScript {}
