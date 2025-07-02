#[starknet::contract]
mod TokenSale {
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use starknet::storage::{
        Map, StoragePathEntry, StorageMapReadAccess, StorageMapWriteAccess,
        StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use core::num::traits::Zero;
    use crate::interfaces::itoken_sale::ITokenSale;
    use crate::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        accepted_payment_token: ContractAddress,
        token_prize: Map<ContractAddress, u256>,
        owner: ContractAddress,
        token_available_for_sale: Map<ContractAddress, u256>,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, accepted_payment_token: ContractAddress,
    ) {
        assert(!owner.is_zero(), 'owner is zero address');
        self.owner.write(owner);

        self.accepted_payment_token.write(accepted_payment_token);
    }

    impl TokenSaleImpl of ITokenSale<ContractState> {
        fn check_available_token(self: @ContractState, token_address: ContractAddress) -> u256 {
            let caller: ContractAddress = get_caller_address();
            // self.token_available_for_sale.entry(caller).read()

            //let get the specific token
            let token = IERC20Dispatcher { contract_address: token_address };

            //let chceck if the token has the balance
            let this_address = get_contract_address();
            let token_balance = token.balance_of(this_address);

            token_balance
        }

        fn deposit_token(
            ref self: ContractState,
            token_address: ContractAddress,
            amount: u256,
            token_prize: u256,
        ) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            let this_address = get_contract_address();
            assert(caller == owner, 'Unauthorized');

            let token_accepted = self.accepted_payment_token.read();
            let token = IERC20Dispatcher { contract_address: token_accepted };

            // get caller's balancce
            let caller_balance = token.balance_of(caller);
            //get this address available balance
            let _this_address_balance = token.balance_of(this_address);

            assert(caller_balance > 0, 'insufficient balance');

            //transfer/deposit token to this address
            let transfer = token.transfer_from(caller, this_address, amount);

            //assert that the transfer was successful
            assert(transfer, 'failed to transfer');

            self.token_available_for_sale.entry(token_address).write(amount);
            self.token_prize.entry(token_address).write(token_prize);
        }
        
        fn buy_token(ref self: ContractState, token_address: ContractAddress, amount: u256) {
            let token_for_sale = self.token_available_for_sale.entry(token_address).read();

            assert(token_for_sale == amount, 'amount be exact');

            let buyer = get_caller_address();
            let this_address = get_contract_address();
            let accepted_token = self.accepted_payment_token.read();

            let payment_token = IERC20Dispatcher { contract_address: accepted_token };
            let token_to_buy = IERC20Dispatcher { contract_address: token_address };

            let buyers_balance = payment_token.balance_of(buyer);
            let buying_prize = self.token_prize.entry(token_address).read();

            assert(buyers_balance == buying_prize, 'insufficient funds');

            payment_token.transfer_from(buyer, this_address, buying_prize);
            token_to_buy.transfer(buyer, self.token_available_for_sale.entry(token_address).read());
        }
    }
}
