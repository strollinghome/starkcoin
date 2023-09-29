use starknet::ContractAddress;

// ERC20 Traits.
#[starknet::interface]
trait IERC20<TCS> {
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
}

// Mint trait.
trait IERC20Mintable<TCS> {
    fn mint(ref self: TCS, account: ContractAddress, amount: u256);
}

// Ownable trait.
trait IOwnable<TCS> {
    fn owner(self: @TCS) -> ContractAddress;
    fn validate_ownership(self: @TCS);
    fn renounce_ownership(ref self: TCS) -> bool;
    fn transfer_ownership(ref self: TCS, new_owner: ContractAddress) -> bool;
}

// Initializable trait.
trait IInitializable<TCS> {
    fn initialize(ref self: TCS, name: felt252, symbol: felt252, owner: ContractAddress);
}

#[starknet::contract]
mod ERC20 {
    use core::zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::contract_address_const;

    // Constants.

    const DECIMALS: u256 = 18_u256;

    // Storage.

    #[storage]
    struct Storage {
        // ERC20 storage.
        balance: LegacyMap::<ContractAddress, u256>,
        allowance: LegacyMap::<(ContractAddress, ContractAddress), u256>,
        name: felt252,
        symbol: felt252,
        total_supply: u256,
        // Ownable storage.
        owner: ContractAddress,
    }

    // Events.

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        Initialized: Initialized,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        from: ContractAddress,
        to: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        owner: ContractAddress,
        spender: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Initialized {
        name: felt252,
        symbol: felt252,
        owner: ContractAddress,
    }

    // Constructor.

    #[constructor]
    fn constructor(
        ref self: ContractState, name: felt252, symbol: felt252, owner: ContractAddress
    ) {
        // Set name and symbol.
        self.name.write(name);
        self.symbol.write(symbol);

        // Set owner.
        self.owner.write(owner);

        // Set total supply.
        self.total_supply.write(0_u256);

        // Emit Initialized event.
        self.emit(Initialized { name: name, symbol: symbol, owner: owner });
    }


    // ERC20 implementation.

    #[external(v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        #[view]
        fn name(self: @ContractState) -> felt252 {
            self.name.read()
        }

        #[view]
        fn symbol(self: @ContractState) -> felt252 {
            self.symbol.read()
        }

        #[view]
        fn decimals(self: @ContractState) -> u256 {
            DECIMALS
        }

        #[view]
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance.read((account))
        }

        #[view]
        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowance.read((owner, spender))
        }

        #[view]
        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            self.transfer_helper(get_caller_address(), recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) -> bool {
            // Get caller balance and decrease its allowance.
            let caller = get_caller_address();
            let sender_allowance = self.allowance.read((sender, caller));
            self.allowance.write((sender, caller), sender_allowance - amount);

            self.transfer_helper(sender, recipient, amount);

            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            // Get sender set allowance for spender.
            let sender = get_caller_address();
            self.allowance.write((sender, spender), amount);

            // Emit Approval event.
            self.emit(Approval { owner: sender, spender: spender, amount: amount });

            true
        }
    }

    #[generate_trait]
    impl TransferHelpers of TransferHelperTrait {
        fn transfer_helper(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) {
            assert(!sender.is_zero(), 'ERC20: sender is 0 address.');
            assert(!recipient.is_zero(), 'ERC20: recipient is 0 address.');

            // Decrease sender balance.
            self.balance.write((sender), self.balance.read(sender) - amount);

            // Increase recipient balance.
            self.balance.write((recipient), self.balance.read(recipient) + amount);

            // Emit Transfer event.
            self.emit(Transfer { from: sender, to: recipient, amount: amount });
        }
    }

    // Mintable ERC20 implementation.

    #[external(v0)]
    impl ERC20MintableImpl of super::IERC20Mintable<ContractState> {
        fn mint(ref self: ContractState, account: ContractAddress, amount: u256) {
            // Check owner is the caller.
            self.validate_ownership();

            // Mint tokens.
            let recipient_balance = self.balance.read((account));
            self.balance.write((account), recipient_balance + amount);

            // Increase total supply.
            let total_supply = self.total_supply.read();
            self.total_supply.write(total_supply + amount);

            // Emit Transfer event.
            self
                .emit(
                    Transfer { from: contract_address_const::<0>(), to: account, amount: amount }
                );
        }
    }

    // Ownable implementation.

    #[external(v0)]
    impl OwnableImpl of super::IOwnable<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn renounce_ownership(ref self: ContractState) -> bool {
            self.validate_ownership();

            self.owner.write(contract_address_const::<0>());
            true
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) -> bool {
            self.validate_ownership();

            self.owner.write(new_owner);
            true
        }

        fn validate_ownership(self: @ContractState) {
            assert(self.owner.read() == get_caller_address(), 'Not owner.');
        }
    }
}
