use array::ArrayTrait;
use debug::PrintTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;

use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use starknet::contract_address_const;
use starknet::testing::set_caller_address;

use snforge_std::{declare, ContractClassTrait, start_prank, stop_prank};

use starkcoin::tests::IERC20TestSafeDispatcher;
use starkcoin::tests::IERC20TestSafeDispatcherTrait;

fn deploy_contract(name: felt252) -> ContractAddress {
    let contract = declare(name);
    contract.deploy(@ArrayTrait::new()).unwrap()
}

#[test]
fn test_initialize() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('ERC20');
    let erc20_safe_dispatcher = IERC20TestSafeDispatcher { contract_address };

    // Initialize.
    erc20_safe_dispatcher.initialize('starkcoin', 'SCOIN', caller_address);

    // Check decimals.
    let decimals = erc20_safe_dispatcher.decimals().unwrap();
    assert(decimals == 18_u256, 'Invalid decimals');

    // Check name.
    let name = erc20_safe_dispatcher.name().unwrap();
    assert(name == 'starkcoin', 'Invalid name');

    // Check symbol.
    let symbol = erc20_safe_dispatcher.symbol().unwrap();
    assert(symbol == 'SCOIN', 'Invalid symbol');

    // Check owner.
    let owner = erc20_safe_dispatcher.owner().unwrap();
    assert(owner == caller_address, 'Invalid owner');
}

// TODO: Ideally we want to check that the call reverts.
#[test]
fn test_reinitialize() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('ERC20');
    let erc20_safe_dispatcher = IERC20TestSafeDispatcher { contract_address };

    // Initialize.
    erc20_safe_dispatcher.initialize('starkcoin', 'SCOIN', caller_address);

    // Reinitialize and fail.
    let new_owner: ContractAddress = contract_address_const::<0>();
    erc20_safe_dispatcher.initialize('new-starkcoin', 'NSCOIN', new_owner);

    // Check values remain unchanged.
    let owner = erc20_safe_dispatcher.owner().unwrap();
    assert(owner == caller_address, 'Invalid owner');
    let name = erc20_safe_dispatcher.name().unwrap();
    assert(name == 'starkcoin', 'Invalid name');
    let symbol = erc20_safe_dispatcher.symbol().unwrap();
    assert(symbol == 'SCOIN', 'Invalid symbol');
}

#[test]
fn test_mint() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('ERC20');
    let erc20_safe_dispatcher = IERC20TestSafeDispatcher { contract_address };

    // Initialize.
    erc20_safe_dispatcher.initialize('starkcoin', 'SCOIN', caller_address);

    // Check balance.
    let balance_before = erc20_safe_dispatcher.balance_of(caller_address).unwrap();
    assert(balance_before == 0, 'Invalid balance');

    // Mint.
    start_prank(contract_address, caller_address);
    erc20_safe_dispatcher.mint(caller_address, 42).unwrap();
    stop_prank(contract_address);

    // Check total supply.
    let total_supply = erc20_safe_dispatcher.total_supply().unwrap();
    assert(total_supply == 42_u256, 'Invalid total supply');

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

    // Check total supply.
    let total_supply = erc20_safe_dispatcher.total_supply().unwrap();
    assert(total_supply == 42_u256, 'Invalid total supply');

    // Transfer
    let recipient_address: ContractAddress = contract_address_const::<43>();
    start_prank(contract_address, caller_address);
    erc20_safe_dispatcher.transfer(recipient_address, 1).unwrap();
    stop_prank(contract_address);

    // Check recipient balance.
    let recipient_balance = erc20_safe_dispatcher.balance_of(recipient_address).unwrap();
    assert(recipient_balance == 1, 'Invalid balance');

    // Check sender balance.
    let sender_balance = erc20_safe_dispatcher.balance_of(caller_address).unwrap();
    assert(sender_balance == 41, 'Invalid balance');
}

#[test]
fn test_allowance_and_transfer_from() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('ERC20');
    let erc20_safe_dispatcher = IERC20TestSafeDispatcher { contract_address };

    // Mint
    erc20_safe_dispatcher.mint(caller_address, 42).unwrap();

    // Check total supply.
    let total_supply = erc20_safe_dispatcher.total_supply().unwrap();
    assert(total_supply == 42_u256, 'Invalid total supply');

    // Approve recipient.
    let recipient_address: ContractAddress = contract_address_const::<43>();
    start_prank(contract_address, caller_address);
    erc20_safe_dispatcher.approve(recipient_address, 1).unwrap();
    stop_prank(contract_address);

    // Check recipient allowance
    let recipient_allowance = erc20_safe_dispatcher
        .allowance(caller_address, recipient_address)
        .unwrap();
    assert(recipient_allowance == 1, 'Invalid balance');

    // Transfer from sender.
    start_prank(contract_address, recipient_address);
    erc20_safe_dispatcher.transfer_from(caller_address, recipient_address, 1).unwrap();
    stop_prank(contract_address);

    let recipient_balance = erc20_safe_dispatcher.balance_of(recipient_address).unwrap();
    assert(recipient_balance == 1, 'Invalid balance');
}

