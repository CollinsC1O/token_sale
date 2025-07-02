use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
pub trait ITokenSale<TState> {
    fn check_available_token(self: @TState, token_address: ContractAddress) -> u256;
    fn deposit_token(
        ref self: TState, token_address: ContractAddress, amount: u256, token_prize: u256,
    );
    fn buy_token(ref self: TState, token_address: ContractAddress, amount: u256);
}

