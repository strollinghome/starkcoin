use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;

use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use starknet::contract_address_const;
use starknet::testing::set_caller_address;

use snforge_std::{declare, ContractClassTrait, start_prank};

use starkcoin::tests::IERC20TestSafeDispatcher;
use starkcoin::tests::IERC20TestSafeDispatcherTrait;

fn deploy_contract(name: felt252) -> ContractAddress {
    let contract = declare(name);
    contract.deploy(@ArrayTrait::new()).unwrap()
}

#[test]
fn test_mint() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('ERC20');
    let erc20_safe_dispatcher = IERC20TestSafeDispatcher { contract_address };

    // Check balance.
    let balance_before = erc20_safe_dispatcher.balance_of(caller_address).unwrap();
    assert(balance_before == 0, 'Invalid balance');

    // Mint.
    erc20_safe_dispatcher.mint(caller_address, 42).unwrap();

    // Check balance.
    let balance_after = erc20_safe_dispatcher.balance_of(caller_address).unwrap();
    assert(balance_after == 42, 'Invalid balance');
}

#[test]
fn test_transfer() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('ERC20');
    let erc20_safe_dispatcher = IERC20TestSafeDispatcher { contract_address };

    // Mint
    erc20_safe_dispatcher.mint(caller_address, 42).unwrap();

    // Transfer
    let recipient_address: ContractAddress = contract_address_const::<43>();
    start_prank(contract_address, caller_address);
    erc20_safe_dispatcher.transfer(recipient_address, 1).unwrap();

    // Check recipient balance.
    let recipient_balance = erc20_safe_dispatcher.balance_of(recipient_address).unwrap();
    assert(recipient_balance == 1, 'Invalid balance');

    // Check sender balance.
    let sender_balance = erc20_safe_dispatcher.balance_of(caller_address).unwrap();
    assert(sender_balance == 41, 'Invalid balance');
}

#[test]
fn test_allowance() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('ERC20');
    let erc20_safe_dispatcher = IERC20TestSafeDispatcher { contract_address };

    // Mint
    erc20_safe_dispatcher.mint(caller_address, 42).unwrap();

    // Approve recipient.
    let recipient_address: ContractAddress = contract_address_const::<43>();
    start_prank(contract_address, caller_address);
    erc20_safe_dispatcher.approve(recipient_address, 1).unwrap();

    // Check recipient allowance
    let recipient_allowance = erc20_safe_dispatcher
        .allowance(caller_address, recipient_address)
        .unwrap();
    assert(recipient_allowance == 1, 'Invalid balance');

    // Transfer from sender.
    start_prank(contract_address, recipient_address);
    erc20_safe_dispatcher.transfer_from(caller_address, recipient_address, 1).unwrap();

    let recipient_balance = erc20_safe_dispatcher.balance_of(recipient_address).unwrap();
    assert(recipient_balance == 1, 'Invalid balance');
}
