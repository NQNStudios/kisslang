package test.cases;

import utest.Test;
import utest.Assert;
import kiss.Prelude;

@:build(kiss.Kiss.build("kiss/src/test/cases/ReaderMacroTestCase.kiss"))
class ReaderMacroTestCase extends Test {
    function testReadBang() {
        Assert.equals("String that takes the rest of the line", ReaderMacroTestCase.myLine());
    }

    function testReadNot() {
        Assert.isTrue(ReaderMacroTestCase.myBool());
    }

    function testDefAlias() {
        Assert.equals(9, ReaderMacroTestCase.mySum);
    }

    function testMultipleInitiators() {
        Assert.equals("b", ReaderMacroTestCase.str1);
        Assert.equals("c", ReaderMacroTestCase.str2);
    }

    function testQuasiquoteMacro() {
        _testQuasiquoteMacro();
    }
}
