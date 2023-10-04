use starkcoin::ascii::AsciiTrait;

#[test]
fn test_ascii() {
    assert(0.is_valid_ascii_string(), '0 is a valid ASCII');
    assert(''.is_valid_ascii_string(), 'Empty string is a valid ASCII');

    // In range.
    assert(32.is_valid_ascii_string(), 'Not valid ASCII');
    assert(126.is_valid_ascii_string(), 'Not valid ASCII');

    // Out of range.
    assert(!31.is_valid_ascii_string(), 'Valid ASCII');
    assert(!127.is_valid_ascii_string(), 'Valid ASCII');

    // 0 byte is not valid ASCII.
    // 0x410041 = 4_259_905 = 'AA' should be invalid
    assert(!4_259_905.is_valid_ascii_string(), '0x410041 not valid ASCII');
}
