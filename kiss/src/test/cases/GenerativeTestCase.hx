package test.cases;

import kiss.Prelude;
import kiss.List;
import utest.Test;
import utest.Assert;

@:build(kiss.Kiss.build())
class GenerativeTestCase extends Test {
    function testTruthy() {
        _testTruthy();
    }

    function testFalsy() {
        _testFalsy();
    }
}
