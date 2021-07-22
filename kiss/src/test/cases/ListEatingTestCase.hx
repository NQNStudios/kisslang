package test.cases;

import utest.Assert;
import utest.Test;
import kiss.Prelude;

@:build(kiss.Kiss.build())
class ListEatingTestCase extends Test {
    function testListEating() {
        _testListEating();
    }
}
