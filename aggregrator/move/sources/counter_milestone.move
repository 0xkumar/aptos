module aggregrator_addr::counter_with_milestone{
    use std::error;
    use std::signer;
    use aptos_framework::aggregator_v2::{Self,Aggregator};
    use aptos_framework::event;

    //Resource being modified doesnt exist
    const ERESOURCE_NOT_PRESENT: u64 = 2;

    //Incrementing a counter failed
    const ECOUNTER_INCREMENT_FAIL: u64 = 4;

    const ENOT_AUTHORISED: u64 = 5;

    struct MilestoneCounter has key{
        next_milestone: u64,
        milestone_every: u64,
        count: Aggregator<u64>,
    }

    #[event]
    struct MilestoneReached has drop, store{
        milestone: u64,
    }

    //Create a Global 'MilestoneCounter'.
    //Stored under the module Publisher address
    public entry fun create(publisher: &signer, milestone_every:u64) {
        assert!(signer::address_of(publisher) == @aggregrator_addr, ENOT_AUTHORISED,);
        move_to<MilestoneCounter>(
            publisher,
            MilestoneCounter{
                next_milestone: milestone_every,
                milestone_every,
                count: aggregator_v2::create_unbounded_aggregator(),
            }
        );
    }

    public entry fun increment_milestone() acquires MilestoneCounter {
        assert!(exists<MilestoneCounter>(@aggregrator_addr), error::invalid_argument(ERESOURCE_NOT_PRESENT));
        let milestone_counter = borrow_global_mut<MilestoneCounter>(@aggregrator_addr);
        //Adds '1' to the 'milestone_counter.count'
        assert!(aggregator_v2::try_add(&mut milestone_counter.count,1),ECOUNTER_INCREMENT_FAIL);
        //Returns 'true' if aggregrator value is larger than or equal to the given 'next_milestone'
        if(aggregator_v2::is_at_least(&milestone_counter.count, milestone_counter.next_milestone) && !aggregator_v2::is_at_least(&milestone_counter.count, milestone_counter.next_milestone +1)) {
            event::emit(MilestoneReached{
                milestone: milestone_counter.next_milestone
            });
            milestone_counter.next_milestone = milestone_counter.next_milestone + milestone_counter.milestone_every;
        }
    }
}