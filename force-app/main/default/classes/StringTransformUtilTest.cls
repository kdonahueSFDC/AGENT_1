/**
 * @description Test class for StringTransformUtil
 */
@IsTest
private class StringTransformUtilTest {

    @IsTest
    static void testTransformListString_ExampleInput() {
        String input = '[120, 0, 120, 0]';
        String result = StringTransformUtil.transformListString(input);
        System.assertEquals('120.00-0.0000-120.00-0.0000', result, 'Expected hyphen-separated 6-char elements');
    }

    @IsTest
    static void testTransformListString_WithSpaces() {
        String input = '[ 120 , 0 , 120 , 0 ]';
        String result = StringTransformUtil.transformListString(input);
        System.assertEquals('120.00-0.0000-120.00-0.0000', result, 'Should trim whitespace around values');
    }

    @IsTest
    static void testTransformListString_DecimalInput() {
        String input = '[1.5, 99.99, 0.1]';
        String result = StringTransformUtil.transformListString(input);
        System.assertEquals('1.5000-99.990-0.1000', result, 'Decimals should format and pad correctly');
    }

    @IsTest
    static void testTransformListString_SingleElement() {
        String input = '[42]';
        String result = StringTransformUtil.transformListString(input);
        System.assertEquals('42.000', result, 'Single element should format without delimiter');
    }

    @IsTest
    static void testTransformListString_EmptyList() {
        String input = '[]';
        String result = StringTransformUtil.transformListString(input);
        System.assertEquals('', result, 'Empty list should return empty string');
    }

    @IsTest
    static void testTransformListString_NullInput() {
        try {
            StringTransformUtil.transformListString(null);
            System.assert(false, 'Expected IllegalArgumentException for null input');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('null or blank'), 'Expected null/blank message');
        }
    }

    @IsTest
    static void testTransformListString_BlankInput() {
        try {
            StringTransformUtil.transformListString('   ');
            System.assert(false, 'Expected IllegalArgumentException for blank input');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('null or blank'), 'Expected null/blank message');
        }
    }

    @IsTest
    static void testTransformListString_InvalidNumericValue() {
        try {
            StringTransformUtil.transformListString('[120, abc, 0]');
            System.assert(false, 'Expected IllegalArgumentException for invalid numeric value');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid numeric value'), 'Expected invalid value message');
        }
    }

    @IsTest
    static void testTransformListString_LargeValueExceedsLimit() {
        try {
            StringTransformUtil.transformListString('[1234567]');
            System.assert(false, 'Expected IllegalArgumentException for value exceeding 6 chars');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('exceeds 6 characters'), 'Expected exceeds message');
        }
    }

    @IsTest
    static void testTransformListString_NegativeNumbers() {
        String input = '[-10.5, 0]';
        String result = StringTransformUtil.transformListString(input);
        System.assertEquals('-10.50-0.0000', result, 'Negative numbers should format correctly');
    }
}
