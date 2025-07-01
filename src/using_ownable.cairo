#[starknet::contract]
mod UsingOwnable {
    use crate::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: MyOwnable, event: MyOwnableEvent);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        MyOwnable: OwnableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        MyOwnableEvent: OwnableComponent::Event,
    }
}
