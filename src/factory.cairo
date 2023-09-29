use starknet::ContractAddress;
use starknet::ClassHash;

// ERC20 Traits.
#[starknet::interface]
trait IFactory<TCS> {
    fn deploy(
        ref self: TCS,
        class_hash: ClassHash,
        salt: felt252,
        name: felt252,
        symbol: felt252,
        owner: ContractAddress,
        supply: u256
    ) -> ContractAddress;
}

#[starknet::contract]
mod Factory {
    use core::result::ResultTrait;
    use starknet::ContractAddress;
    use starknet::ClassHash;
    use starknet::get_caller_address;
    use starknet::deploy_syscall;
    use starknet::get_contract_address;
    use array::ArrayTrait;
    use starkcoin::mintable::IERC20MintableSafeDispatcher;
    use starkcoin::mintable::IERC20MintableSafeDispatcherTrait;
    use starkcoin::ownable::IOwnableSafeDispatcher;
    use starkcoin::ownable::IOwnableSafeDispatcherTrait;

    #[storage]
    struct Storage {
        class_hash: ClassHash,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Deployed: Deployed
    }

    #[derive(Drop, starknet::Event)]
    struct Deployed {
        name: felt252,
        symbol: felt252,
        owner: ContractAddress,
        supply: u256,
        contract_address: ContractAddress,
    }

    #[external(v0)]
    impl FactoryImpl of super::IFactory<ContractState> {
        fn deploy(
            ref self: ContractState,
            class_hash: ClassHash,
            salt: felt252,
            name: felt252,
            symbol: felt252,
            owner: ContractAddress,
            supply: u256
        ) -> ContractAddress {
            // Set constructor arguments.
            let mut constructor_calldata = ArrayTrait::new();
            constructor_calldata.append(name);
            constructor_calldata.append(symbol);
            constructor_calldata.append(get_contract_address().into());

            // Deploy ERC20 contract.
            let (contract_address, _) = deploy_syscall(
                class_hash, salt, constructor_calldata.span(), false
            )
                .unwrap();

            // Mint supply to owner.
            IERC20MintableSafeDispatcher { contract_address }.mint(owner, supply);

            // Transfer ownership.
            IOwnableSafeDispatcher { contract_address }.transfer_ownership(owner);

            self
                .emit(
                    Deployed {
                        name: name,
                        symbol: symbol,
                        owner: owner,
                        supply: supply,
                        contract_address: contract_address,
                    }
                );

            contract_address
        }
    }
}
