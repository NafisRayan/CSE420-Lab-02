#include "scope_table.h"

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count)
    {
        this->bucket_count = bucket_count;
        this->current_scope_id = 1;  // Start with global scope as ID 1
        this->current_scope = new scope_table(bucket_count, current_scope_id, NULL);
    }

    void enter_scope()
    {
        current_scope_id++;
        scope_table* new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
        current_scope = new_scope;
    }

    void exit_scope()
    {
        if (current_scope == NULL) return;

        scope_table* parent = current_scope->get_parent_scope();
        delete current_scope;
        current_scope = parent;
    }

    bool insert(symbol_info* symbol)
    {
        if (current_scope == NULL) return false;
        return current_scope->insert_in_scope(symbol);
    }

    symbol_info* lookup(symbol_info* symbol)
    {
        if (symbol == NULL) return NULL;

        scope_table* temp = current_scope;
        while (temp != NULL) {
            symbol_info* found = temp->lookup_in_scope(symbol);
            if (found != NULL) {
                return found;
            }
            temp = temp->get_parent_scope();
        }
        return NULL;
    }

    // Lookup by name
    symbol_info* lookup_symbol(string name)
    {
        symbol_info temp(name, "");
        return lookup(&temp);
    }

    // Check if a symbol exists in current scope only
    symbol_info* lookup_current_scope(string name)
    {
        if (current_scope == NULL) return NULL;

        symbol_info temp(name, "");
        return current_scope->lookup_in_scope(&temp);
    }

    void print_current_scope()
    {
        if (current_scope != NULL) {
            ofstream outlog("21301559_log.txt", ios::app);  // Open in append mode
            current_scope->print_scope_table(outlog);
            outlog.close();
        }
    }

    void print_all_scopes(ofstream& outlog)
    {
        outlog << "################################" << endl << endl;
        scope_table *temp = current_scope;
        while (temp != NULL)
        {
            temp->print_scope_table(outlog);
            temp = temp->get_parent_scope();
        }
        outlog << "################################" << endl << endl;
    }

    ~symbol_table()
    {
        // Delete all scopes starting from current scope
        while (current_scope != NULL) {
            scope_table* parent = current_scope->get_parent_scope();
            delete current_scope;
            current_scope = parent;
        }
    }

    // Helper methods for the compiler
    bool insert_variable(string name, string type)
    {
        // Check if already exists in current scope
        if (lookup_current_scope(name) != NULL) {
            return false; // Already exists
        }

        symbol_info* symbol = new symbol_info(name, "ID", type);
        return insert(symbol);
    }

    bool insert_array(string name, string type, int size)
    {
        // Check if already exists in current scope
        if (lookup_current_scope(name) != NULL) {
            return false; // Already exists
        }

        symbol_info* symbol = new symbol_info(name, "ID", type, size);
        return insert(symbol);
    }

    bool insert_function(string name, string return_type, vector<string> param_types)
    {
        // Check if already exists in current scope
        symbol_info* existing = lookup_current_scope(name);
        if (existing != NULL) {
            // If it's already a function with the same signature, it's a redefinition
            if (existing->is_function() &&
                existing->get_data_type() == return_type &&
                existing->get_param_types() == param_types) {
                return false; // Function redefinition
            }

            // Otherwise it's a different entity with the same name
            return false;
        }

        symbol_info* symbol = new symbol_info(name, "ID", return_type, param_types);
        return insert(symbol);
    }

    // Log methods for compiler output
    void log_enter_scope(ofstream& outlog)
    {
        outlog << "New ScopeTable with id " << current_scope_id << " created" << endl;
    }

    void log_exit_scope(ofstream& outlog)
    {
        outlog << "ScopeTable with id " << current_scope->get_unique_id() << " removed" << endl;
    }
};
