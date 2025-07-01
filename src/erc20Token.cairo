// name() ➤ Confirm the token name.
// symbol() ➤ Confirm the token symbol.
// decimals() ➤ View the token’s decimal places (usually 18).
// totalSupply() ➤ Check total number of tokens in circulation.
// balanceOf(address) ➤ Check the token balance of:
// 1. Your own account
// 2. Another devnet account

use starknet::ContractAddress;
#[starknet::interface]
pub trait IMyToken<TContractState> {
    // fn name(self: @TContractState) -> ByteArray;
    // fn symbol(self: @TContractState) -> ByteArray;
    // fn decimals(self: @TContractState) -> u8;
    // fn totalSupply(self: @TContractState) -> u256;
    // fn balanceOf(self: @TContractState, account: ContractAddress) -> u256;
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn burn(ref self: TContractState, account: ContractAddress, amount: u256);
}

#[starknet::contract]
pub mod MyToken {
    //use openzeppelin_token::erc20::interface::IERC20;
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin_access::ownable::OwnableComponent;
    use starknet::ContractAddress;
    use core::byte_array::ByteArray;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl OwnableTwoStepMixinImpl =
        OwnableComponent::OwnableTwoStepMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, recipient: ContractAddress, owner: ContractAddress) {
        let name = "MrT_Token";
        let symbol = "MTTK";
        //let initial_supply = 1000000;

        self.erc20.initializer(name, symbol);
        //self.erc20.mint(recipient, initial_supply);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl MyTokenImpl of super::IMyToken<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            //let initial_supply = 1000000;
            self.ownable.assert_only_owner();
            self.erc20.mint(recipient, amount)
        }

        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            self.ownable.assert_only_owner();
            self.erc20.burn(account, amount);
        }
    }
}
