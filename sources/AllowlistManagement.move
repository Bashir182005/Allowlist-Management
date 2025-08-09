module allowlist_addr::allowlist_management {
    use std::signer;
    use aptos_framework::timestamp;
    use std::table::{Self, Table};
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_EXPIRED: u64 = 2;
    struct AllowlistEntry has store, drop {
        expiration_time: u64,
    }
    struct Allowlist has key {
        entries: Table<address, AllowlistEntry>,
        admin: address,
    }
    fun init_module(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        move_to(admin, Allowlist {
            entries: table::new(),
            admin: admin_addr,
        });
    }
    public entry fun add_to_allowlist(
        admin: &signer,
        target_address: address,
        expiration_timestamp: u64
    ) acquires Allowlist {
        let admin_addr = signer::address_of(admin);
        let allowlist = borrow_global_mut<Allowlist>(@allowlist_addr);
        
        assert!(admin_addr == allowlist.admin, E_NOT_AUTHORIZED);
        
        let entry = AllowlistEntry {
            expiration_time: expiration_timestamp,
        };
        
        table::upsert(&mut allowlist.entries, target_address, entry);
    }
    public fun is_allowed(target_address: address): bool acquires Allowlist {
        if (!exists<Allowlist>(@allowlist_addr)) {
            return false
        };
        
        let allowlist = borrow_global<Allowlist>(@allowlist_addr);
        
        if (!table::contains(&allowlist.entries, target_address)) {
            return false
        };
        
        let entry = table::borrow(&allowlist.entries, target_address);
        let current_time = timestamp::now_seconds();
        
        current_time < entry.expiration_time
    }

}
