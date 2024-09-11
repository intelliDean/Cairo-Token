use core::starknet::ContractAddress;

#[starknet::interface]
pub trait MiniTrait<T> {
    fn mint(ref self: T, receiver: ContractAddress, amount: u128);
    fn transfer(ref self: T, receiver: ContractAddress, _amount: u128) -> bool;
    fn balance_of(self: @T, _owner: ContractAddress) -> u128;
}

#[starknet::contract]
pub mod Mini {

    use core::starknet:: {ContractAddress, get_caller_address};
    use core::starknet::storage:: {
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess
    };

    #[storage]
    struct Storage {
        owner: ContractAddress,
        balances: Map<ContractAddress, u128>,
        name: felt252,
        symbol: felt252,
        decimal: u8
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MintToken: MintToken,
        TransferToken: TransferToken,
        Deployer: Deployer
    }

    #[derive(Drop, starknet::Event)]
    struct MintToken {
        #[key]
        receiver: ContractAddress,
        amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct TransferToken {
        #[key]
        sender: ContractAddress,
        #[key] 
        receiver: ContractAddress,
        amount: u128
    }

    #[derive(Drop, starknet::Event)]
    struct Deployer {
        #[key]
        deployer: ContractAddress
    }

    #[constructor]
    fn constructor (ref self: ContractState, _name: felt252, _symbol: felt252, _decimal: u8, _owner: ContractAddress) {
        
        self.name.write(_name);
        self.symbol.write(_symbol);
        self.decimal.write(_decimal);
        self.owner.write(_owner);

        self.emit(Deployer{
            deployer: _owner
        });
    }

    #[abi(embed_v0)]
    impl Mini of super::MiniTrait<ContractState> {

        fn mint(ref self: ContractState, receiver: ContractAddress, amount: u128) {
            //only owner
            self.only_owner();

            //this is where the minting is done
            self.balances.entry(receiver).write(amount);

            self.emit(MintToken {
                receiver: receiver,
                amount: amount
            })
        }

        fn transfer(ref self: ContractState, receiver: ContractAddress, _amount: u128) -> bool {

            let caller = get_caller_address();
            let caller_balance = self.balances.entry(caller).read();

            assert(caller_balance >= _amount, 'Insufficient balance');

            self.balances.entry(caller).write(caller_balance - _amount);

            self.balances.entry(receiver).write(self.balances.entry(receiver).read() + _amount);

            self.emit(TransferToken {
                sender: caller,
                receiver: receiver,
                 amount: _amount
            });

            true
        }
        
        fn balance_of(self: @ContractState, _owner: ContractAddress) -> u128 {

            self.balances.entry(_owner).read()
        }
    }


    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait {

        fn only_owner(self: @ContractState) {
            
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
        }
    }
}