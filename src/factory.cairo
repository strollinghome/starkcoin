use starknet::ContractAddress;
use starknet::ClassHash;

// ERC20 Traits.
#[starknet::interface]
trait IFactory<TCS> {
    fn deploy(
        ref self: TCS, name: felt252, symbol: felt252, owner: ContractAddress, supply: u256
    ) -> ContractAddress;
}

#[starknet::contract]
mod Factory {
    use core::result::ResultTrait;
    use starknet::ContractAddress;
    use starknet::ClassHash;
    use starknet::class_hash_try_from_felt252;
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

    #[constructor]
    fn constructor(ref self: ContractState, class_hash: felt252) {
        self.class_hash.write(class_hash_try_from_felt252(class_hash).unwrap());
    }

    #[external(v0)]
    impl FactoryImpl of super::IFactory<ContractState> {
        fn deploy(
            ref self: ContractState,
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
                self.class_hash.read(), 1, constructor_calldata.span(), false
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
