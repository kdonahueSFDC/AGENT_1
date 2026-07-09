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

    /**
     * @description Bulk test to validate StringTransformUtil handles large payloads (200+ elements)
     * without hitting governor limits (heap size, CPU time). This ensures the utility is
     * bulkified and safe for high-volume scenarios.
     * Uses Test.startTest/stopTest to reset governor limits for accurate testing.
     */
    @IsTest
    static void testTransformStringWithBulkData() {
        // Build a comma-separated string with 250 numeric values to exceed bulk threshold
        List<String> values = new List<String>();
        for (Integer i = 1; i <= 250; i++) {
            values.add(String.valueOf(i));
        }
        String bulkInput = '[' + String.join(values, ', ') + ']';

        Test.startTest();
        String result;
        try {
            result = StringTransformUtil.transformListString(bulkInput);
        } catch (Exception e) {
            System.assert(false, 'Bulk processing should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();

        // Validate the result contains all 250 elements formatted correctly
        List<String> resultElements = result.split('-');
        System.assertEquals(250, resultElements.size(), 'Should contain 250 formatted elements');

        // Spot check first, middle, and last elements for correct format
        System.assertEquals('1.0000', resultElements[0], 'First element should be formatted as 1.0000');
        System.assertEquals('125.00', resultElements[124], 'Middle element (125) should be formatted correctly');
        System.assertEquals('250.00', resultElements[249], 'Last element should be formatted as 250.00');

        // Verify each element is exactly 6 characters (fixed-width format)
        for (String element : resultElements) {
            System.assertEquals(6, element.length(), 'Each element must be exactly 6 characters: ' + element);
        }

        // Additional assertion: no exception indicates heap/CPU limits were not exceeded
        System.assertNotEquals(null, result, 'Result should not be null for bulk data');
    }
}
