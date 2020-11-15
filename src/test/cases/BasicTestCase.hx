package test.cases;

import utest.Test;
import utest.Assert;
import kiss.Prelude;

@:build(kiss.Kiss.build("src/test/cases/BasicTestCase.kiss"))
class BasicTestCase extends Test {
    function testStaticVar() {
        Assert.equals("Howdy", BasicTestCase.message);
    }

    function testHaxeInsertion() {
        Assert.equals(23, BasicTestCase.mathResult);
    }

    function testStaticFunction() {
        Assert.equals(6, BasicTestCase.myFloor(6.5));
    }

    function testFuncall() {
        Assert.equals(7, BasicTestCase.funResult);
    }

    function testField() {
        Assert.equals(5, new BasicTestCase().myField);
    }

    function testMethod() {
        Assert.equals(5, new BasicTestCase().myMethod());
    }

    function testArray() {
        var arr = BasicTestCase.myArray;
        Assert.equals(3, arr.length);
        Assert.equals(1, arr[0]);
        Assert.equals(2, arr[1]);
        Assert.equals(3, arr[2]);

        // Kiss arrays can be negatively indexed like Python
        Assert.equals(3, arr[-1]);
        Assert.equals(2, arr[-2]);
        Assert.equals(1, arr[-3]);
    }

    function testArrayAccess() {
        Assert.equals(3, BasicTestCase.myArrayLast);
    }

    function testVariadicAdd() {
        Assert.equals(6, BasicTestCase.mySum);
    }

    function testVariadicSubtract() {
        Assert.equals(-2, BasicTestCase.myDifference);
    }

    function testVariadicMultiply() {
        Assert.equals(60, BasicTestCase.myProduct);
    }

    function testVariadicDivide() {
        Assert.equals(0.5, BasicTestCase.myQuotient);
    }

    function testMod() {
        Assert.equals(4, BasicTestCase.myRemainder);
    }

    function testPow() {
        Assert.equals(256, BasicTestCase.myPower);
    }

    function testUnop() {
        Assert.equals(7, BasicTestCase.myInc);
    }
}
