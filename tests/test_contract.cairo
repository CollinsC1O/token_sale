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

use starknet::{ContractAddress, contract_address_const, get_contract_address};

use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, spy_events, EventSpyAssertionsTrait
};


#[starknet::interface]
pub trait IERC20PlusMintBurn<TContractState> {
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

fn OWNER() -> ContractAddress {
    'owner'.try_into().expect('owner')
}

//========================//
//To use E18
//========================//
const ONE_E18: u256 = 1000000000000000000_u256;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();

    //let OWNER: ContractAddress = contract_address_const::<0x123456789>();

    //prepare constructor calldata. consider that we are to pass the owner param in our constructor
    //when deploying
    let mut constructor_calldata = array![];

    OWNER().serialize(ref constructor_calldata);

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

#[test]
fn test_constructor() {
    let contract_address = deploy_contract("MyToken");

    let erc20_token = IERC20PlusMintBurnDispatcher { contract_address };

    let name = erc20_token.name();
    let symbol = erc20_token.symbol();

    assert(name == "MrT_Token", 'wrong token name');
    assert(symbol == "MTTK", 'wrong token symbol');
}

#[test]
fn test_total_supply_and_balances() {
    let contract_address = deploy_contract("MyToken");
    let erc20_token = IERC20PlusMintBurnDispatcher { contract_address };

    let decimal = erc20_token.decimals();

    let min_amount = 1000_u256 * decimal.into();

    let total_supply_before_mint = erc20_token.total_supply();

    //get recipient
    let recipient: ContractAddress = contract_address_const::<0x123>();

    //check balance of recipient
    let balance_b4_mint = erc20_token.balance_of(recipient);

    //assert that total supply before_mint is zero
    assert(total_supply_before_mint == 0, 'invalid balance');

    //===============================//
    //mint token to a recipient
    //===============================//

    start_cheat_caller_address(contract_address, OWNER());

    erc20_token.mint(recipient, min_amount);

    stop_cheat_caller_address(contract_address);

    let total_supply_after_mint = erc20_token.total_supply();

    let balance_after_mint = erc20_token.balance_of(recipient);

    //assert that total supply after_mint, is min_amount
    assert(total_supply_after_mint == min_amount, 'wrong supply');

    //assert that balcce before mint is zero
    assert(balance_b4_mint == 0, 'wrong balance before mint');

    //assert recipient balance increase
    assert(balance_after_mint == min_amount, 'wrong balance after mint');

    println!("total supply before mint is: {}", total_supply_before_mint);
    println!("total supply after mint is: {}", total_supply_after_mint);
}

#[test]
fn test_mint_and_burn_function() {
    let contract_address = deploy_contract("MyToken");

    let erc20_token = IERC20PlusMintBurnDispatcher { contract_address };

    //lets get zero address where we are burning to
    let zero_address: ContractAddress = contract_address_const::<0>();

    //get total supply
    let total_supply_b4_mint = erc20_token.total_supply();

    //get decimal
    let decimal = erc20_token.decimals();

    let min_amount = 1000_u256 * decimal.into();
    let burn_amount = 500 * decimal.into();

    //get recipient
    let recipient: ContractAddress = contract_address_const::<0x123>();

    //assert total supply before burn is zero
    assert(total_supply_b4_mint == 0, 'invalid total supply');

    let owner = OWNER();

    //mint token
    start_cheat_caller_address(contract_address, OWNER());
    erc20_token.mint(recipient, min_amount);
    stop_cheat_caller_address(contract_address);

    //recipient balance after mint
    let recipient_balance_after_mint = erc20_token.balance_of(recipient);
    //get total supply after mint
    let total_supply_after_mint = erc20_token.total_supply();
    //recipient balance after mint
    assert(recipient_balance_after_mint == min_amount, 'invalid recipient balance');
    //total supply after mint
    assert(total_supply_after_mint == min_amount, 'invalid total supply after mint');

    //let this_contract = get_contract_address();
    //burn token
    start_cheat_caller_address(contract_address, OWNER());
    erc20_token.burn(recipient, burn_amount);
    stop_cheat_caller_address(contract_address);

    //lets get recipient balance after burning
    let recipient_balance_after_burn = erc20_token.balance_of(recipient);
    //get total supply after burning
    let total_supply_after_burn = erc20_token.total_supply();
    assert(total_supply_after_burn == burn_amount, 'invalid total supply after burn');
    assert(recipient_balance_after_burn == burn_amount, 'invalid cecipient balance')
}

#[test]
fn test_approve() {
    let contract_address = deploy_contract("MyToken");

    let erc20_token = IERC20PlusMintBurnDispatcher { contract_address };

    let token_decimal = erc20_token.decimals();
    let mint_amount = 1000_u256 * token_decimal.into();
    let approve_amount = 100_u256 * token_decimal.into();

    let recipient: ContractAddress = 0x23434ef343444b123456789ef123456789fd23434ef343444ab
        .try_into()
        .unwrap();

    start_cheat_caller_address(contract_address, OWNER());

    let owner: ContractAddress = OWNER();
    //mint to owner
    erc20_token.mint(owner, mint_amount);
    // stop_cheat_caller_address(contract_address);

    erc20_token.approve(recipient, approve_amount);
    stop_cheat_caller_address(contract_address);

    //=============================================================================
    //Note: if you don't prank the owner the know that it is the contract instance
    //      that make's the ownable calls, such as aprove etc.
    //=============================================================================

    let balance_of_owner = erc20_token.balance_of(owner);

    assert(balance_of_owner == mint_amount, 'mint to owner failed');

    let allowance = erc20_token.allowance(owner, recipient);
    assert(allowance > 0, 'wrong approval');
    assert(allowance == approve_amount, 'not approved');

    println!("owner balance is: {}", balance_of_owner);
    println!("approved ammount is: {}", approve_amount);
}

#[test]
fn test_transfer() {
    let contract_address = deploy_contract("MyToken");

    let erc20_token = IERC20PlusMintBurnDispatcher { contract_address };

    let owner: ContractAddress = OWNER();
    //get recipient
    let recipient: ContractAddress = contract_address_const::<0x123>();
    //get decimal
    let decimal = erc20_token.decimals();

    let min_amount = 1000_u256 * decimal.into();
    let transfer_amount = 500 * decimal.into();

    start_cheat_caller_address(contract_address, owner);
    //mint to owner
    erc20_token.mint(owner, min_amount);
    //transfer from owner to recipient
    erc20_token.transfer(recipient, transfer_amount);
    stop_cheat_caller_address(contract_address);

    let recipient_balance = erc20_token.balance_of(recipient);
    let owner_balance = erc20_token.balance_of(recipient);

    assert_eq!(recipient_balance, transfer_amount, "transfer failed");
    assert(owner_balance == min_amount - transfer_amount, 'wrong owner balance');
    println!("the balance of owner after mint: {}", owner_balance);

    let total_supply = erc20_token.total_supply();
    println!("the total supply after mint and transfer: {}", total_supply);
}

#[test]
fn test_transfer_from() {
    let contract_address = deploy_contract("MyToken");

    let erc20_token = IERC20PlusMintBurnDispatcher { contract_address };

    let owner: ContractAddress = OWNER();
    //get recipient
    let recipient: ContractAddress = contract_address_const::<0x123>();
    //get decimal
    let decimal = erc20_token.decimals();

    let min_amount = 1000_u256 * ONE_E18;
    let transfer_amount = 500 * decimal.into();
    let approve_amount = 500 * decimal.into();

    start_cheat_caller_address(contract_address, owner);
    //mint to owner
    erc20_token.mint(owner, min_amount);
    //allow the caller to transfer from the owner to the recipient
    erc20_token.approve(owner, approve_amount);
    //transfer from owner to recipient
    erc20_token.transfer_from(owner, recipient, transfer_amount);
    stop_cheat_caller_address(contract_address);

    let recipient_balance_after_transfer = erc20_token.balance_of(recipient);
    assert(recipient_balance_after_transfer == transfer_amount, 'transfer from failed');
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


