package test.cases;

import utest.Test;
import utest.Assert;
import kiss.Prelude;

class OnceTestCase extends Test {
    function testOnce() {
        new OnceTestObject();
        new OnceTestObject();
        Assert.equals(1, OnceTestObject.staticCount);
        Assert.equals(2, OnceTestObject.instanceCount);
    }
}

@:build(kiss.Kiss.build("OnceTestObject.kiss"))
class OnceTestObject {}
