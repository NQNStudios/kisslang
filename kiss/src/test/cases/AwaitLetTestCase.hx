package test.cases;

import utest.Test;
import utest.Assert;
import kiss.Prelude;
#if js
import js.lib.Promise;
#end
import utest.Async;

@:build(kiss.Kiss.build())
class AwaitLetTestCase extends Test {
    function testMultipleBindings(async:Async) {
        _testMultipleBindings(async);
    }

    function testRejectedPromise(async:Async) {
        _testRejectedPromise(async);
    }
}