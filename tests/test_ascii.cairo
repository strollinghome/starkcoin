use traits::{DivRem};
use starkcoin::ascii::is_valid_ascii_string;

#[test]
fn test_ascii() {
    // In range.
    assert(is_valid_ascii_string(32), 'Not valid ASCII');
    assert(is_valid_ascii_string(126), 'Not valid ASCII');

    // Out of range.
    assert(!is_valid_ascii_string(31), 'Valid ASCII');
    assert(!is_valid_ascii_string(127), 'Valid ASCII');
}

