package test.cases;

import utest.Test;
import utest.Assert;
import kiss.Prelude;

@:build(kiss.Kiss.build("src/test/cases/ReaderMacroTestCase.kiss"))
class ReaderMacroTestCase extends Test {
    function testReadBang() {
        Assert.equals("String that takes the rest of the line", ReaderMacroTestCase.myLine());
    }

    function testDefAlias() {
        Assert.equals(9, ReaderMacroTestCase.mySum);
    }
}
