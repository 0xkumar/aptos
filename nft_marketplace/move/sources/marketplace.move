module marketplace_addr::marketplace{
    use std::error;
    use std::signer;
    use std::option;
    use aptos_std::smart_vector;
    use aptos_framework::aptos_account;
    use aptos_framework::coin;
    use aptos_framework::object;

    #[test_only]
    friend marketplace_addr::test_marketplace;

    const APP_OBJECT_SEED: vector<u8> = b"MARKETPLACE";
    //There exists no listing
    const ENO_LISTING: u64 = 1;
    //There exists no seller
    const ENO_SELLER: u64 = 2;

    //core data structure

    struct MarketplaceSigner has key{
        extend_ref: object::extend_Ref,
    }

    struct Sellers has key {
        ///All Addresses of sellers.
        addresses: smart_vector::SmartVector<address>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Listing has key{
        //The item owned by this listing, transferred to the new owner at the end.
        object: object::Object<object::ObjectCore>,
        //The Seller of the object
        seller: address,
        //used to clean up at the end
        delete_ref: object::DeleteRef,
        //Used to create a signer to transfer the listed item,
        extended_ref: object::ExtendRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct FixedPriceListing<phantom CoinType> has key{
        //The price to purchase the item up for listing
        price: u64,
    }

    struct SellerListings has key {
        //All object addresses of listings the user has created.
        listings: smart_vector:: SmartVector<address>
    }

    //Functions

    //This function is only called once when the module is pusblished for the first time
    fun init_module(deployer: &signer) {
        let constructor_ref = object::create_named_object(
            deployer,
            APP_OBJECT_SEED,
        );

        let extend_ref = object::generate_extend_ref(&constructor_ref);
        let marketplace_signer = &object::generate_signer(&constructor_ref);

        move_to(marketplace_signer, MarketplaceSigner{
            extend_ref,
        });
    }

    //Entry Functions
    //List an time for same at a fixed price
    public entry fun list_with_fixed_price<CoinType>(
        seller:&signer,
        object: object::Object<object::ObjectCore>,
        price: u64,
    ) acquires SellerListings, Sellers, MarketplaceSigner{
        list_with_fixed_price_internal<CoinType>(seller,object,price);
    }

    //Purchase outright an item from a fixed price listing
    public entry fun purchase<CoinType> {
        purchaser: &signer,
        object: object::Object<object::ObjectCore>,
    }acquires FixedPriceListing, Listing, SellerListing, Sellers{
        let listing_addr = object::object_address(&object);

        assert!(exists<Listing>(listing_addr), error::not_found(ENO_LISTING));
        assert!(exists<FixedPriceListing<CoinType>>(listing_addr),error::not_found(ENO_LISTING));

        let FixedPriceListing{
            price,
        } = move_from<FixedPriceListing<CoinType>>(listing_addr);

        //The Listing has conculded, transfer the asset and delete the listing. Returns the seller
        //for depositing any profit.

        let coins = coin::withdraw<CoinType>(purchaser,price);
    }

}
