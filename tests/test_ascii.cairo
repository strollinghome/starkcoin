use starkcoin::ascii::AsciiTrait;

#[test]
fn test_ascii() {
    // In range.
    assert(32.is_valid_ascii_string(), 'Not valid ASCII');
    assert(126.is_valid_ascii_string(), 'Not valid ASCII');

    // Out of range.
    assert(!31.is_valid_ascii_string(), 'Valid ASCII');
    assert(!127.is_valid_ascii_string(), 'Valid ASCII');
}


#[test]
fn test_ascii_char() {
    assert(!'abcd\terminatorabcd'.is_valid_ascii_string(), 'Not valid ASCII');
}

