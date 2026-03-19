/**
 * @description Utility class for transforming string representations of numeric lists
 * into hyphen-separated, fixed-width formatted strings.
 * @author Salesforce
 */
public with sharing class StringTransformUtil {

    /** Target length for each formatted element in the output string. */
    private static final Integer ELEMENT_LENGTH = 6;

    /** Number of decimal places for numeric formatting. */
    private static final Integer DECIMAL_PLACES = 2;

    /** Delimiter used to join formatted elements. */
    private static final String OUTPUT_DELIMITER = '-';

    /**
     * @description Transforms a string representation of a numeric list into a
     * hyphen-separated string where each element is formatted to exactly 6 characters
     * with two decimal places.

     * @param input String in format "[120, 0, 120, 0]" (brackets, comma-separated values)
     * @return Formatted string like "120.00-0.0000-120.00-0.0000"
     * @throws IllegalArgumentException if input is null, blank, or contains invalid format
     */
    public static String transformListString(String input) {
        if (String.isBlank(input)) {
            throw new IllegalArgumentException('Input cannot be null or blank');
        }

        // Remove leading '[' and trailing ']', then trim
        String trimmed = input.trim();
        if (trimmed.startsWith('[')) {
            trimmed = trimmed.substring(1);
        }
        if (trimmed.endsWith(']')) {
            trimmed = trimmed.substring(0, trimmed.length() - 1);
        }

        if (String.isBlank(trimmed)) {
            return '';
        }

        // Split by comma and process each value
        List<String> rawValues = trimmed.split(',');
        List<String> formattedElements = new List<String>();

        for (String rawValue : rawValues) {
            String valueStr = rawValue.trim();
            if (valueStr.length() == 0) {
                continue;
            }
            formattedElements.add(formatElement(valueStr));
        }

        return String.join(formattedElements, OUTPUT_DELIMITER);
    }

    /**
     * @description Formats a single numeric string to exactly 6 characters with 2 decimal places.
     * Pads with trailing zeros when the formatted value is shorter than 6 characters.
     *
     * @param valueStr Trimmed string representation of a number
     * @return Formatted 6-character string (e.g., "120.00" or "0.0000")
     */
    private static String formatElement(String valueStr) {
        Decimal numValue;
        try {
            numValue = Decimal.valueOf(valueStr);
        } catch (TypeException e) {
            throw new IllegalArgumentException('Invalid numeric value: ' + valueStr, e);
        }

        // Format to 2 decimal places using HALF_UP rounding
        Decimal scaled = numValue.setScale(DECIMAL_PLACES, System.RoundingMode.HALF_UP);
        String formatted = String.valueOf(scaled);

        // Pad with trailing zeros to reach exactly 6 characters
        while (formatted.length() < ELEMENT_LENGTH) {
            formatted += '0';
        }

        if (formatted.length() > ELEMENT_LENGTH) {
            throw new IllegalArgumentException(
                'Value "' + valueStr + '" exceeds 6 characters when formatted: ' + formatted
            );
        }

        return formatted;
    }
}
