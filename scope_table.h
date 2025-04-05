#include "symbol_info.h"

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    int hash_function(string name)
    {
        unsigned long hash = 5381;
        for (char c : name) {
            hash = ((hash << 5) + hash) + c; // hash * 33 + c
        }
        return hash % bucket_count;
    }

public:
    scope_table() : bucket_count(0), unique_id(0), parent_scope(nullptr) {}
    
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
    }
    scope_table *get_parent_scope() { return parent_scope; }
    int get_unique_id() { return unique_id; }

    symbol_info *lookup_in_scope(symbol_info* symbol)
    {
        int index = hash_function(symbol->get_name());
        for(auto item : table[index]) {
            if(item->get_name() == symbol->get_name()) {
                return item;
            }
        }
        return nullptr;
    }

    bool insert_in_scope(symbol_info* symbol)
    {
        if(lookup_in_scope(symbol) != nullptr) {
            return false;
        }
        
        int index = hash_function(symbol->get_name());
        table[index].push_front(symbol);
        return true;
    }

    bool delete_from_scope(symbol_info* symbol)
    {
        int index = hash_function(symbol->get_name());
        auto& bucket = table[index];
        
        for(auto it = bucket.begin(); it != bucket.end(); ++it) {
            if((*it)->get_name() == symbol->get_name()) {
                bucket.erase(it);
                return true;
            }
        }
        return false;
    }
    void print_scope_table(ofstream& outlog);

    // you can add more methods if you need
};

void scope_table::print_scope_table(ofstream& outlog)
{
    outlog << "ScopeTable # " + to_string(unique_id) << endl;

    for(int i = 0; i < bucket_count; i++) {
        if(!table[i].empty()) {
            outlog << "Bucket " << i << " --> ";
            for(auto symbol : table[i]) {
                outlog << "<" << symbol->get_name() << ", " << symbol->get_type();
                
                if(symbol->get_kind() == "array") {
                    outlog << ", array size " << symbol->get_array_size();
                }
                else if(symbol->get_kind() == "function") {
                    outlog << ", " << symbol->get_return_type();
                    outlog << ", {";
                    auto params = symbol->get_param_types();
                    for(size_t j = 0; j < params.size(); j++) {
                        outlog << params[j];
                        if(j < params.size() - 1) outlog << ", ";
                    }
                    outlog << "}";
                }
                
                outlog << "> ";
            }
            outlog << endl;
        }
    }
}

~scope_table()
{
    for(auto& bucket : table) {
        bucket.clear();
    }
    table.clear();
}
