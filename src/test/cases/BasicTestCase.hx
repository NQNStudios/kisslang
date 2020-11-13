package test.cases;

import utest.Test;
import utest.Assert;

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
}
