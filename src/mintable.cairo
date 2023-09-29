use starknet::ContractAddress;

// Mint trait.
#[starknet::interface]
trait IERC20Mintable<TCS> {
    fn mint(ref self: TCS, account: ContractAddress, amount: u256);
}
