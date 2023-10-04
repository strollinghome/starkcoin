trait AsciiTrait<T> {
    fn is_valid_ascii_string(self: T) -> bool;
}

impl AsciiTraitImpl of AsciiTrait<felt252> {
    fn is_valid_ascii_string(self: felt252) -> bool {
        let mut value: u256 = self.into();

        // Check each byte of the string.
        let valid: bool = loop {
            if (value.is_zero()) {
                break true;
            }

            let remainder: u256 = value % 256_u256;

            if (remainder < 32) {
                break false;
            }

            if (remainder > 126) {
                break false;
            }

            value = value / 256_u256;
        };

        valid
    }
}
