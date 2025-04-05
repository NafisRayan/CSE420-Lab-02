#include "symbol_info.h"
#include <fstream>

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
    scope_table() : bucket_count(0), unique_id(0), parent_scope(NULL) {}

    scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
    {
        this->bucket_count = bucket_count;
        this->unique_id = unique_id;
        this->parent_scope = parent_scope;
        table.resize(bucket_count);
    }

    scope_table *get_parent_scope()
    {
        return parent_scope;
    }

    int get_unique_id()
    {
        return unique_id;
    }

    symbol_info *lookup_in_scope(symbol_info* symbol)
    {
        if (!symbol) return nullptr;
        
        string name = symbol->get_name();
        int index = hash_function(name);
        
        for (symbol_info* current : table[index]) {
            if (current->get_name() == name) {
                return current;
            }
        }
        return nullptr;
    }

    bool insert_in_scope(symbol_info* symbol)
    {
        if (!symbol) return false;
        
        // Check if symbol already exists in this scope
        if (lookup_in_scope(symbol)) {
            return false;
        }

        int index = hash_function(symbol->get_name());
        table[index].push_front(symbol);
        return true;
    }

    bool delete_from_scope(symbol_info* symbol)
    {
        if (!symbol) return false;
        
        string name = symbol->get_name();
        int index = hash_function(name);
        
        auto& bucket = table[index];
        for (auto it = bucket.begin(); it != bucket.end(); ++it) {
            if ((*it)->get_name() == name) {
                delete *it;  // Free memory
                bucket.erase(it);
                return true;
            }
        }
        return false;
    }

    void print_scope_table(ofstream& outlog)
    {
        outlog << "ScopeTable # " << unique_id << endl;

        for (int i = 0; i < bucket_count; i++) {
            if (!table[i].empty()) {
                outlog << "Bucket " << i << " --> ";
                for (symbol_info* symbol : table[i]) {
                    outlog << symbol->to_string() << " ";
                }
                outlog << endl;
            }
        }
    }

    ~scope_table()
    {
        // Free all symbol_info objects
        for (auto& bucket : table) {
            for (auto symbol : bucket) {
                delete symbol;
            }
            bucket.clear();
        }
        table.clear();
    }
};
