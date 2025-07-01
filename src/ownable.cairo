use starknet::ContractAddress;

#[starknet::interface]
trait IOwnable<TContractState> {
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TContractState);
}

pub mod Errors {
    pub const CALLER_NOT_OWNER: felt252 = 'caller not owner';
    pub const ZERO_ADDRESS_CALLER: felt252 = 'caller is zero address';
}

#[starknet::component]
pub mod OwnableComponent {
    use super::{ContractAddress, Errors};
    use starknet::{get_caller_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use core::num::traits::Zero;

    #[storage]
    pub struct Storage {
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        OwnershipTransfer: OwnershipTransfer,
    }

    #[derive(Drop, starknet::Event)]
    pub struct OwnershipTransfer {
        pub previous_owner: ContractAddress,
        pub new_owner: ContractAddress,
    }

    #[embeddable_as(Ownable)]
    pub impl OwnableImpl<
        TContractState, +HasComponent<TContractState>,
    > of super::IOwnable<ComponentState<TContractState>> {
        fn owner(self: @ComponentState<TContractState>) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress,
        ) {
            assert(!new_owner.is_zero(), Errors::ZERO_ADDRESS_CALLER);
            self.assert_only_owner();
            self._transfer_ownership(new_owner);
        }

        fn renounce_ownership(ref self: ComponentState<TContractState>) {
            self.assert_only_owner();
            self._transfer_ownership(Zero::zero());
        }
    }

    #[generate_trait]
    pub impl InternalImpl<
        TContractState, +HasComponent<TContractState>,
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            self._transfer_ownership(owner);
        }

        fn _transfer_ownership(
            ref self: ComponentState<TContractState>, new_owner: ContractAddress,
        ) {
            let previous_owner = self.owner.read();

            assert(!new_owner.is_zero(), Errors::ZERO_ADDRESS_CALLER);

            self.owner.write(new_owner);
        }

        fn assert_only_owner(self: @ComponentState<TContractState>) {
            let owner = self.owner.read();
            let caller = get_caller_address();
            assert(caller == owner, Errors::CALLER_NOT_OWNER);
        }
    }
}
//=======emiting an event in component========//


