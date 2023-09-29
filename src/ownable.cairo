use starknet::ContractAddress;

// Ownable trait.
#[starknet::interface]
trait IOwnable<TCS> {
    fn owner(self: @TCS) -> ContractAddress;
    fn validate_ownership(self: @TCS);
    fn renounce_ownership(ref self: TCS) -> bool;
    fn transfer_ownership(ref self: TCS, new_owner: ContractAddress) -> bool;
}
