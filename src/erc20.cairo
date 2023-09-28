use starknet::{ContractAddress};

#[starknet::interface]
trait IERC20<TContractState> {
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
}

trait IERC20Mintable<TContractState> {
    fn mint(ref self: TContractState, account: ContractAddress, amount: u256);
}

#[starknet::contract]
mod ERC20 {
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use starknet::contract_address_const;

    // Storage.

    #[storage]
    struct Storage {
        balance: LegacyMap::<ContractAddress, u256>,
        allowance: LegacyMap::<(ContractAddress, ContractAddress), u256>
    }

    // Events.

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
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

    // ERC20 Implementation.

    #[external(v0)]
    impl ERC20Impl of super::IERC20<ContractState> {
        // TODO: Add initialize function.

        fn name(self: @ContractState) -> felt252 {
            1
        }

        fn symbol(self: @ContractState) -> felt252 {
            1
        }

        fn decimals(self: @ContractState) -> felt252 {
            18
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balance.read((account))
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            self.allowance.read((owner, spender))
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            // Get sender balance and decrease it.
            let sender = get_caller_address();
            let sender_balance = self.balance.read((sender));
            self.balance.write((sender), sender_balance - amount);

            // Get recipient balance and increase it.
            let recipient_balance = self.balance.read((recipient));
            self.balance.write((recipient), recipient_balance + amount);

            // Emit Transfer event.
            self.emit(Transfer { from: sender, to: recipient, amount: amount });

            return true;
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

            // Get sender balance and decrease it.
            let sender_balance = self.balance.read((sender));
            self.balance.write((sender), sender_balance - amount);

            // Get recipient balance and increase it.
            let recipient_balance = self.balance.read((recipient));
            self.balance.write((recipient), recipient_balance + amount);

            // Emit Transfer event.
            self.emit(Transfer { from: sender, to: recipient, amount: amount });

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

    // Mintable ERC20 Implementation.

    #[external(v0)]
    impl ERC20MintableImpl of super::IERC20Mintable<ContractState> {
        fn mint(ref self: ContractState, account: ContractAddress, amount: u256) {
            let recipient_balance = self.balance.read((account));
            self.balance.write((account), recipient_balance + amount);

            self
                .emit(
                    Transfer { from: contract_address_const::<0>(), to: account, amount: amount }
                );
        }
    }
}
