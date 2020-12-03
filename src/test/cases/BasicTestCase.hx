package test.cases;

import utest.Test;
import utest.Assert;
import kiss.Prelude;
import kiss.List;

using StringTools;

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
        Assert.equals(7, BasicTestCase.myNum);
    }

    function testMin() {
        Assert.equals(1, BasicTestCase.myMin);
    }

    function testMax() {
        Assert.equals(9, BasicTestCase.myMax);
    }

    function testLessThan() {
        _testLessThan();
    }

    function testLesserEqual() {
        _testLesserEqual();
    }

    function testGreaterThan() {
        _testGreaterThan();
    }

    function testGreaterEqual() {
        _testGreaterEqual();
    }

    function testEqual() {
        _testEqual();
    }

    function testIf() {
        _testIf();
    }

    function testMacros() {
        Assert.equals(7, BasicTestCase.incrementTwice(5));

        var seasonsGreetings = "ho ";
        Assert.equals("ho ho ho ", BasicTestCase.doTwiceString(() -> {
            seasonsGreetings += "ho ";
        }));
    }

    // TODO to really test typed variable definitions, check for compilation failure on a bad example
    function testTypedDefvar() {
        Assert.equals(8, BasicTestCase.myInt);
    }

    function testTryCatch() {
        Assert.equals(5, BasicTestCase.myTryCatch("string error"));
        Assert.equals(6, BasicTestCase.myTryCatch(404));
        Assert.equals(7, BasicTestCase.myTryCatch(["list error"]));
    }

    function testTypeCheck() {
        Assert.equals(5, BasicTestCase.myTypeCheck());
    }

    function testGroups() {
        Assert.equals([[1, 2], [3, 4]].toString(), BasicTestCase.myGroups1().toString());
        Assert.equals([[1, 2, 3], [4]].toString(), BasicTestCase.myGroups2().toString());
    }

    function testLet() {
        _testLet();
    }

    function testConstructors() {
        Assert.equals("sup", BasicTestCase.myConstructedString);
    }

    function testCond() {
        Assert.equals("this one", BasicTestCase.myCond1);
        Assert.equals("the default", BasicTestCase.myCond2);
        Assert.equals("this", BasicTestCase.myCond3);
        Assert.equals(null, BasicTestCase.myCondFallthrough);
    }

    function testSetAndDeflocal() {
        Assert.equals("another thing", BasicTestCase.mySetLocal());
    }

    function testOr() {
        Assert.equals(5, BasicTestCase.myOr1);
    }

    function testAnd() {
        Assert.equals(6, BasicTestCase.myAnd1);
        Assert.equals(null, BasicTestCase.myAnd2);
        Assert.equals(null, BasicTestCase.myAnd3);
    }

    function testNot() {
        Assert.equals(false, BasicTestCase.myNot1);
        Assert.equals(false, BasicTestCase.myNot2);
    }

    function testLambda() {
        Assert.equals([5, 6].toString(), BasicTestCase.myFilteredList.toString());
    }

    function testWhen() {
        Assert.equals(6, BasicTestCase.myWhen1);
    }

    function testQuickNths() {
        _testQuickNths();
    }

    function testListDestructuring() {
        _testListDestructuring();
    }

    function testDoFor() {
        _testDoFor();
    }

    function testOptionalArguments() {
        myOptionalFunc(5);
    }

    function testRestArguments() {
        Assert.equals(5, myRest1);
        Assert.equals(5, myRest2);
        Assert.equals(5, myRest3);
    }

    function testCombinedOptRest() {
        Assert.equals("abcd", myCombined1);
        Assert.equals("aboop", myCombined2);
        Assert.equals("ab", myCombined3);
    }

    function testFieldExps() {
        _testFieldExps();
    }

    function testBreakContinue() {
        _testBreakContinue();
    }
}
