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
        symbol_info* symbol = new symbol_info(name, "ID", type);
        return insert(symbol);
    }

    bool insert_array(string name, string type, int size)
    {
        symbol_info* symbol = new symbol_info(name, "ID", type, size);
        return insert(symbol);
    }

    bool insert_function(string name, string return_type, vector<string> param_types)
    {
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
