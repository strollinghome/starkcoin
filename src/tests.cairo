use starknet::{ContractAddress};
use starknet::ClassHash;

#[starknet::interface]
trait ITest<TCS> {
    // Read functions.
    fn name(self: @TCS,) -> felt252;
    fn symbol(self: @TCS,) -> felt252;
    fn decimals(self: @TCS,) -> u256;
    fn balance_of(self: @TCS, account: ContractAddress) -> u256;
    fn allowance(self: @TCS, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn total_supply(self: @TCS) -> u256;

    // Write functions.
    fn transfer(ref self: TCS, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TCS, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
    fn approve(ref self: TCS, spender: ContractAddress, amount: u256) -> bool;

    // Mint.
    fn mint(ref self: TCS, account: ContractAddress, amount: u256);

    // Initialize.
    fn initialize(ref self: TCS, name: felt252, symbol: felt252, owner: ContractAddress);

    // Ownable.
    fn owner(self: @TCS) -> ContractAddress;
    fn validate_ownership(self: @TCS);
    fn renounce_ownership(ref self: TCS) -> bool;
    fn transfer_ownership(ref self: TCS, new_owner: ContractAddress) -> bool;

    // Factory.
    fn deploy(
        self: @TCS,
        class_hash: ClassHash,
        salt: felt252,
        name: felt252,
        symbol: felt252,
        owner: ContractAddress
    ) -> ContractAddress;
}
