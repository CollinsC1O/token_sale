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
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn burn(ref self: TContractState, account: ContractAddress, amount: u256) -> bool;
}


#[starknet::contract]
pub mod MyToken {
    //use openzeppelin_token::erc20::interface::IERC20;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::{ContractAddress, get_caller_address};
    use core::num::traits::Zero;

    //use token_sale::interfaces::ierc20::IERC20;
    use super::IMyToken;

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
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        let name = "MrT_Token";
        let symbol = "MTTK";
        //let initial_supply = 1000000;

        self.erc20.initializer(name, symbol);
        //self.erc20.mint(recipient, initial_supply);
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl IMyTokenImpl of IMyToken<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            //let initial_supply = 1000000;
            self.ownable.assert_only_owner();
            self.erc20.mint(recipient, amount);

            true
        }

        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) -> bool {
            self.ownable.assert_only_owner();
            assert(!account.is_zero(), 'you cannot burn to address zero');
            self.erc20.burn(account, amount);

            true
        }
    }
}
