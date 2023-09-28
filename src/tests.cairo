use starknet::{ContractAddress};

#[starknet::interface]
trait IERC20Test<TContractState> {
    // Read functions.
    fn name(self: @TContractState,) -> felt252;
    fn symbol(self: @TContractState,) -> felt252;
    fn decimals(self: @TContractState,) -> felt252;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;

    // Write functions.
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;

    // Mint
    fn mint(ref self: TContractState, account: ContractAddress, amount: u256);
}
