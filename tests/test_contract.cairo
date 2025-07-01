///////////////////////// TYPES OF TESTING IN CAIRO ///////////////////////////////
/// Unit Testing
/// Integration Testing
/// End-End Testing
/// Fruzz Testing
/// Fork Testing
/// Inverent Testing

///====== Integration Testing ======///

// use erc20::IHelloStarknetSafeDispatcher;
// use erc20::IHelloStarknetSafeDispatcherTrait;
// use erc20::IHelloStarknetDispatcher;
// use erc20::IHelloStarknetDispatcherTrait;

use starknet::{ContractAddress, contract_address_const};

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use crate::erc20Token::{IMyTokenDispatcher, IMyTokenDispatcherTrait};
use core::num::traits::Zero;

//use erc20::IMyToken::{IMyTokenDispatcher, IMyTokenDispatcherTrait};

#[starknet::interface]
pub trait IERC20PlusMint<TContractState> {
    // IERC20Metadata
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;

    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;

    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn burn(ref self: TContractState, account: ContractAddress, amount: u256);
}

//use erc20::{IMyTokenDispatcher, IMyTokenDispatcherTrait}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    // let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    // contract_address

    let mut constructor_calldata = ArrayTrait::new();

    let token_name: ByteArray = "MyToken";
    let token_symbol: ByteArray = "MTK";
    let initial_supply: u256 = 1000000_u256;
    let recipient: ContractAddress = starknet::contract_address_const::<0x123456789>();

    token_name.serialize(ref constructor_calldata);
    token_symbol.serialize(ref constructor_calldata);
    initial_supply.serialize(ref constructor_calldata);
    recipient.serialize(ref constructor_calldata);

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    contract_address
}

#[test]
fn test_constructor() {
    let contract_address = deploy_contract("MyToken");

    let erc20_token = IERC20PlusMintDispatcher { contract_address };

    let name = erc20_token.name();
    let symbol = erc20_token.symbol();

    assert(name == "MrT_Token", 'wrong token name');
    assert(symbol == "MTTK", 'wrong token symbol');
}

#[test]
fn test_total_supply() {
    let contract_address = deploy_contract("MyToken");

    let erc20_token = IERC20PlusMintDispatcher { contract_address };

    let token_recipient: ContractAddress = contract_address_const::<0x123456789>();

    let decimals = erc20_token.decimals();

    let balance_before_mint = erc20_token.balance_of(token_recipient);

    let mint_amount = 100_u256 * decimals.into();

    erc20_token.mint(token_recipient, mint_amount);

    let total_supply = erc20_token.total_supply();
    let balance_after_mint = erc20_token.balance_of(token_recipient);

    assert!(total_supply == mint_amount, "wrong supply");
    //before
    assert!(balance_before_mint == 0, "wrong balance");
    //after
    assert!(balance_after_mint == 0, "wrong balance");
}
// #[test]
// #[feature("safe_dispatcher")]
// fn test_cannot_increase_balance_with_zero_value() {
//     let contract_address = deploy_contract("HelloStarknet");

//     let safe_dispatcher = IHelloStarknetSafeDispatcher { contract_address };

//     let balance_before = safe_dispatcher.get_balance().unwrap();
//     assert(balance_before == 0, 'Invalid balance');

//     match safe_dispatcher.increase_balance(0) {
//         Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
//         Result::Err(panic_data) => {
//             assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
//         }
//     };
// }


