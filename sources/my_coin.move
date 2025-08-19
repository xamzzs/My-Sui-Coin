/// Create a simple coin with icon.
module my_coin::my_coin {
    use sui::coin::{Self, TreasuryCap};
    use sui::tx_context::{sender, TxContext};
    use sui::transfer;
    use std::option;
    use sui::url::{Self, Url};

    /// OTW and the type for the Token.
    struct MY_COIN has drop {}

    // Most of the magic happens in the initializer for the demonstration
    // purposes; however half of what's happening here could be implemented as
    // a single / set of PTBs.
    fun init(otw: MY_COIN, ctx: &mut TxContext) {
        let treasury_cap = create_currency(otw, ctx);
        transfer::public_transfer(treasury_cap, sender(ctx));
    }

    /// Internal: not necessary, but moving this call to a separate function for
    /// better visibility of the Closed Loop setup in `init`.
    fun create_currency<T: drop>(
        otw: T,
        ctx: &mut TxContext
    ): TreasuryCap<T> {
        let url = url::new_unsafe_from_bytes(b"https://iamtzar.com/wp-content/uploads/2025/08/01.png");

        let (treasury_cap, metadata) = coin::create_currency(
            otw, 9,
            b"MC",
            b"My Coin",
            b"My First Ever Coin",
            option::some(url),
            ctx
        );

        transfer::public_freeze_object(metadata);
        treasury_cap
    }

    /// Mint `amount` of `Coin` and send it to `recipient`.
    public entry fun mint(
        c: &mut TreasuryCap<MY_COIN>, 
        amount: u64, 
        recipient: address, 
        ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(c, amount, recipient, ctx);
    }

    #[test_only]
    public fun init_for_test(ctx: &mut TxContext) {
        init(MY_COIN{}, ctx);
    }
}

#[test_only]
/// Implements tests for most common scenarios for the coin example.
module my_coin::my_coin_tests {
    use my_coin::my_coin::{MY_COIN, init_for_test};
    use sui::coin::{Self, TreasuryCap};
    use sui::test_scenario as ts;

    #[test]
    fun mint_transfer_update() {
        let addr1 = @0xA;
        let addr2 = @0xB;

        // init simple_token module
        let scenario = ts::begin(addr1);
        {
            init_for_test(ts::ctx(&mut scenario));
        };

        // mint
        ts::next_tx(&mut scenario, addr1);
        {
            let tc = ts::take_from_sender<TreasuryCap<MY_COIN>>(&scenario);
            coin::mint_and_transfer<MY_COIN>(&mut tc, 10000000000, addr2, ts::ctx(&mut scenario));
            ts::return_to_sender(&scenario, tc);
        };

        ts::end(scenario);
    }
}
