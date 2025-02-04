module billboard_addr::billboard{
    use std::error;
    use std::signer;
    use std::string::{String};
    use std::vector;
    use aptos_framework::event;
    use aptos_framework::timestamp;

    const ENOT_OWNER: u64 = 1;
    const MAX_MESSAGES: u64 = 5;

    struct Billboard has key{
        messages: vector<Message>,//[]
        oldest_index: u64 //0
    }

    struct Message has store, copy, drop {
        sender: address,
        message: String,
        added_at: u64
    }

    #[event]
    struct AddedMessage has drop, store{
        sender: address,
        message: String,
        added_at: u64
    }

    //Initialization
    fun init_module(owner: &signer){
        move_to(owner, Billboard{
            messages: vector[],
            oldest_index: 0
        })
    }

    public entry fun add_message(sender: &signer, message: String) acquires Billboard{
        let message = Message{
            sender: signer::address_of(sender),
            message,
            added_at: timestamp::now_seconds()
        };

        //Event Emitting for the added message
        event::emit(AddedMessage{
            sender: message.sender,
            message: message.message,
            added_at: message.added_at
        });
        //Returns the billboard of the Owner 'Deployer'.
        let billboard = borrow_global_mut<Billboard>(@billboard_addr);
        //Returns the length of the Vector.
        if (vector::length(&billboard.messages) < MAX_MESSAGES) {
            //Adds the 'message' at the end of the 'billboard.messages' vector
            vector::push_back(&mut billboard.messages, message);
            return
        };
        //'vector::borrow_mut' returns a mutable reference to the element at the index 'billboard.oldest_index'.
        *vector::borrow_mut(&mut billboard.messages, billboard.oldest_index) = message;
        billboard.oldest_index = (billboard.oldest_index + 1) % MAX_MESSAGES; //Not Understand
    }
    //Clear All the messages from the billboard.
    public entry fun clear(owner: &signer) acquires Billboard{
        only_owner(owner);
        let billboard = borrow_global_mut<Billboard>(@billboard_addr);
        billboard.messages = vector[];
        billboard.oldest_index = 0;
    }

    inline fun only_owner(owner: &signer){
        assert!(signer::address_of(owner) == @billboard_addr, error::permission_denied(ENOT_OWNER));
    }


    #[view]
    public fun get_messages(): vector<Message> acquires Billboard{
        let billboard = borrow_global<Billboard>(@billboard_addr);
        let messages = vector[];
        vector::for_each(billboard.messages, |m| vector::push_back(&mut messages,m));
        vector::rotate(&mut messages, billboard.oldest_index);
        messages
    }

    #[test(aptos_framework = @std, owner = @billboard_addr, alice = @0x1234, bob=@0xb0b)]
    fun test_billboard_happy_path(
        aptos_framework: &signer,
        owner: &signer,
        alice: &signer,
        bob: &signer
    ) acquires Billboard{
        use std::string;
        timestamp::set_time_has_started_for_testing(aptos_framework); //Initializes the testing time mechanism
        timestamp::update_global_time_for_test_secs(1000); //Sets a specific timestamp (1000) sec for the test

        init_module(owner);
        let msgs = get_messages();
        assert!(vector::length(&msgs) == 0, 1);

        let alice_message = string::utf8(b"alice's message");
        let bob_message = string::utf8(b"bob's message");

        add_message(alice,alice_message);
        add_message(bob, bob_message);
        msgs = get_messages();
        //There must be only 2 messages
        assert!(vector::length(&msgs) == 2, 1);
        //First message Checks
        assert!(vector::borrow(&msgs,0).message == alice_message, 1);
        assert!(vector::borrow(&msgs,0).sender == signer::address_of(alice),1);
        //Second message Checks
        assert!(vector::borrow(&msgs,1).message == bob_message,1);
        assert!(vector::borrow(&msgs,1).sender == signer::address_of(bob),1);


        add_message(alice, alice_message);
        add_message(alice, alice_message);
        add_message(alice, alice_message);
        add_message(alice, alice_message);

        msgs = get_messages();
        assert!(vector::length(&msgs) == 5,1);

        clear(owner);

    }
}


/*
//Rotate
rotate(&mut[mut[1,2,3,4,5],2]) --> [3,4,5,1,2]

//Push_back
Add 't' to the end of self.

//borrow_mut
Return a mutable reference to the element at the index 'i'.

//length 
Return the length of the vector 'self'.
*/

/*
for_each is a higher-order function that applies a closure to each element of the vector
Example:

let nums = vector[1, 2, 3];
let doubled = vector[];
vector::for_each(nums, |n| vector::push_back(&mut doubled, n * 2));
// doubled becomes [2, 4, 6]

*/
