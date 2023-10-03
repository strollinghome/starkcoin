use traits::DivRem;

fn is_valid_ascii_string(short_string: u256) -> bool {
    if short_string.is_zero() {
        return true;
    }

    let (quotient, remainder) = DivRem::div_rem(short_string, 256_u256.try_into().unwrap());

    if (remainder < 32) || (remainder > 126) {
        return false;
    }

    is_valid_ascii_string(quotient)
}
