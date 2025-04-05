#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    string kind;  // "variable", "array", "function"
    string data_type;  // int, float, void etc.
    int array_size;  // for arrays
    string return_type;  // for functions
    vector<string> param_types;  // for function parameter types
    symbol_info* next;  // for hash table chaining

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
    }
    symbol_info(string name, string type, string kind = "variable", string data_type = "") : next(nullptr)
    {
        this->name = name;
        this->type = type;
        this->kind = kind;
        this->data_type = data_type;
        this->array_size = -1;
    }

    string get_name() { return name; }
    string get_type() { return type; }
    string get_kind() { return kind; }
    string get_data_type() { return data_type; }
    int get_array_size() { return array_size; }
    string get_return_type() { return return_type; }
    vector<string> get_param_types() { return param_types; }
    symbol_info* get_next() { return next; }

    void set_name(string name) { this->name = name; }
    void set_type(string type) { this->type = type; }
    void set_kind(string kind) { this->kind = kind; }
    void set_data_type(string data_type) { this->data_type = data_type; }
    void set_array_size(int size) { this->array_size = size; }
    void set_return_type(string type) { this->return_type = type; }
    void set_param_types(vector<string> params) { this->param_types = params; }
    void set_next(symbol_info* next) { this->next = next; }

    ~symbol_info()
    {
        next = nullptr;
    }
};
