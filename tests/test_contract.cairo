use array::ArrayTrait;

use debug::PrintTrait;

use result::ResultTrait;

use option::OptionTrait;

use traits::TryInto;

use starknet::ContractAddress;
use starknet::ClassHash;
use starknet::Felt252TryIntoContractAddress;
use starknet::contract_address_const;
use starknet::testing::set_caller_address;

use snforge_std::declare;
use snforge_std::ContractClassTrait;
use snforge_std::start_prank;
use snforge_std::stop_prank;

use starkcoin::tests::ITestSafeDispatcher;
use starkcoin::tests::ITestSafeDispatcherTrait;

fn deploy_contract(
    name: felt252, symbol: felt252, owner: ContractAddress, supply: u256,
) -> ContractAddress {
    // Get ERC20 class_hash
    let class_hash: ClassHash = declare('ERC20').class_hash;

    // Deploy factory.
    let contract = declare('Factory');
    let mut constructor_calldata = ArrayTrait::<felt252>::new();
    constructor_calldata.append(class_hash.into());

    let factory_address = contract.deploy(@constructor_calldata).unwrap();

    // Deploy ERC20.
    let factory_safe_dispatcher = ITestSafeDispatcher { contract_address: factory_address };
    let erc20_contract_address: ContractAddress = factory_safe_dispatcher
        .deploy(name, symbol, owner, supply)
        .unwrap();

    return erc20_contract_address;
}

#[test]
fn test_deploy() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('starkcoin', 'SCOIN', caller_address, 0);
    let erc20_safe_dispatcher = ITestSafeDispatcher { contract_address };

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

#[test]
fn test_mint() {
    let caller_address: ContractAddress = contract_address_const::<42>();
    let contract_address = deploy_contract('starkcoin', 'SCOIN', caller_address, 42);
    let erc20_safe_dispatcher = ITestSafeDispatcher { contract_address };

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
    let contract_address = deploy_contract('starkcoin', 'SCOIN', caller_address, 42);
    let erc20_safe_dispatcher = ITestSafeDispatcher { contract_address };

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
    let contract_address = deploy_contract('starkcoin', 'SCOIN', caller_address, 42);
    let erc20_safe_dispatcher = ITestSafeDispatcher { contract_address };

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

#[test]
fn test_invalid_ascii_name_and_symbol() {
    let caller_address_0: ContractAddress = contract_address_const::<42>();

    // Get ERC20 class_hash
    let class_hash: ClassHash = declare('ERC20').class_hash;

    // Deploy factory.
    let contract = declare('Factory');
    let mut constructor_calldata = ArrayTrait::<felt252>::new();
    constructor_calldata.append(class_hash.into());

    let factory_address = contract.deploy(@constructor_calldata).unwrap();

    // Deploy ERC20.
    let factory_safe_dispatcher = ITestSafeDispatcher { contract_address: factory_address };

    // Should error.
    let mut err = factory_safe_dispatcher
        .deploy(1.into(), 'SCOIN', caller_address_0, 0)
        .unwrap_err();
    assert(@err.pop_front().unwrap() == @'Name not valid ASCII.', 'should error.');

    err = factory_safe_dispatcher.deploy('starkcoin', 1.into(), caller_address_0, 0).unwrap_err();
    assert(@err.pop_front().unwrap() == @'Symbol not valid ASCII.', 'should error.');
}


#[test]
fn test_unique_name() {
    let caller_address_0: ContractAddress = contract_address_const::<42>();
    let caller_address_1: ContractAddress = contract_address_const::<41>();

    // Get ERC20 class_hash
    let class_hash: ClassHash = declare('ERC20').class_hash;

    // Deploy factory.
    let contract = declare('Factory');
    let mut constructor_calldata = ArrayTrait::<felt252>::new();
    constructor_calldata.append(class_hash.into());

    let factory_address = contract.deploy(@constructor_calldata).unwrap();

    // Deploy ERC20.
    let factory_safe_dispatcher = ITestSafeDispatcher { contract_address: factory_address };
    // Should work.
    factory_safe_dispatcher.deploy('starkcoin', 'SCOIN_0', caller_address_0, 0);
    // Should error.
    let mut err = factory_safe_dispatcher
        .deploy('starkcoin', 'SCOIN_1', caller_address_1, 0)
        .unwrap_err();

    assert(@err.pop_front().unwrap() == @'Name must be unique.', 'should error.');
}

#[test]
fn test_unique_symbol() {
    let caller_address_0: ContractAddress = contract_address_const::<42>();
    let caller_address_1: ContractAddress = contract_address_const::<41>();

    // Get ERC20 class_hash
    let class_hash: ClassHash = declare('ERC20').class_hash;

    // Deploy factory.
    let contract = declare('Factory');
    let mut constructor_calldata = ArrayTrait::<felt252>::new();
    constructor_calldata.append(class_hash.into());

    let factory_address = contract.deploy(@constructor_calldata).unwrap();

    // Deploy ERC20.
    let factory_safe_dispatcher = ITestSafeDispatcher { contract_address: factory_address };
    // Should work.
    factory_safe_dispatcher.deploy('starkcoin_0', 'SCOIN', caller_address_0, 0);
    // Should error.
    let mut err = factory_safe_dispatcher
        .deploy('starkcoin_1', 'SCOIN', caller_address_1, 0)
        .unwrap_err();

    assert(@err.pop_front().unwrap() == @'Symbol must be unique.', 'should error.');
}

#[test]
fn test_disallowed_symbol() {
    let caller_address_0: ContractAddress = contract_address_const::<42>();

    // Get ERC20 class_hash
    let class_hash: ClassHash = declare('ERC20').class_hash;

    // Deploy factory.
    let contract = declare('Factory');
    let mut constructor_calldata = ArrayTrait::<felt252>::new();
    constructor_calldata.append(class_hash.into());

    let factory_address = contract.deploy(@constructor_calldata).unwrap();

    // Deploy ERC20.
    let factory_safe_dispatcher = ITestSafeDispatcher { contract_address: factory_address };

    // Should error.

    let mut err = factory_safe_dispatcher
        .deploy('starkcoin', 'ETH', caller_address_0, 0)
        .unwrap_err();
    assert(@err.pop_front().unwrap() == @'Invalid symbol.', 'should error.');

    err = factory_safe_dispatcher.deploy('starkcoin', 'WETH', caller_address_0, 0).unwrap_err();
    assert(@err.pop_front().unwrap() == @'Invalid symbol.', 'should error.');

    err = factory_safe_dispatcher.deploy('starkcoin', 'USDC', caller_address_0, 0).unwrap_err();
    assert(@err.pop_front().unwrap() == @'Invalid symbol.', 'should error.');

    err = factory_safe_dispatcher.deploy('starkcoin', 'DAI', caller_address_0, 0).unwrap_err();
    assert(@err.pop_front().unwrap() == @'Invalid symbol.', 'should error.');
}

