#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;
    string kind;         // "variable", "array", or "function"
    string data_type;    // "int", "float", "void", etc.
    int array_size;      // -1 for non-arrays
    vector<string> param_types;  // parameter types for functions
    symbol_info* next;   // for hash table chaining

    // For semantic analysis
    bool is_error;       // Flag to mark if this symbol has a semantic error

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->kind = "variable";  // default
        this->data_type = "";
        this->array_size = -1;
        this->next = nullptr;
        this->is_error = false;
    }

    // Constructor for variables
    symbol_info(string name, string type, string data_type)
    {
        this->name = name;
        this->type = type;
        this->kind = "variable";
        this->data_type = data_type;
        this->array_size = -1;
        this->next = nullptr;
        this->is_error = false;
    }

    // Constructor for arrays
    symbol_info(string name, string type, string data_type, int size)
    {
        this->name = name;
        this->type = type;
        this->kind = "array";
        this->data_type = data_type;
        this->array_size = size;
        this->next = nullptr;
        this->is_error = false;
    }

    // Constructor for functions
    symbol_info(string name, string type, string return_type, vector<string> params)
    {
        this->name = name;
        this->type = type;
        this->kind = "function";
        this->data_type = return_type;  // stores return type for functions
        this->array_size = -1;
        this->param_types = params;
        this->next = nullptr;
        this->is_error = false;
    }

    // Getters
    string get_name() { return name; }
    string get_type() { return type; }
    string get_kind() { return kind; }
    string get_data_type() { return data_type; }
    int get_array_size() { return array_size; }
    vector<string> get_param_types() { return param_types; }
    symbol_info* get_next() { return next; }
    bool get_is_error() { return is_error; }

    // Setters
    void set_name(string name) { this->name = name; }
    void set_type(string type) { this->type = type; }
    void set_kind(string kind) { this->kind = kind; }
    void set_data_type(string data_type) { this->data_type = data_type; }
    void set_array_size(int size) { this->array_size = size; }
    void set_param_types(vector<string> params) { this->param_types = params; }
    void set_next(symbol_info* next) { this->next = next; }
    void set_is_error(bool is_error) { this->is_error = is_error; }

    // Type checking methods
    bool is_int() { return data_type == "int"; }
    bool is_float() { return data_type == "float"; }
    bool is_void() { return data_type == "void"; }
    bool is_numeric() { return is_int() || is_float(); }
    bool is_array() { return kind == "array"; }
    bool is_function() { return kind == "function"; }

    // Type compatibility check
    bool is_compatible_with(symbol_info* other) {
        // Both must be numeric types
        if (!is_numeric() || !other->is_numeric()) return false;

        // If both are the same type, they are compatible
        if (data_type == other->data_type) return true;

        // Float is compatible with int (but will generate a warning for int = float)
        return true;
    }

    string to_string() const {
        string info = "<" + name + ", " + type;
        if (kind == "array") {
            info += ", " + data_type + "[" + std::to_string(array_size) + "]";
        }
        else if (kind == "function") {
            info += ", " + data_type + ", {";
            for (size_t i = 0; i < param_types.size(); i++) {
                if (i > 0) info += ", ";
                info += param_types[i];
            }
            info += "}";
        }
        info += ">";
        return info;
    }

    ~symbol_info()
    {
        // No dynamic memory allocated in this class
        // next pointer will be managed by scope_table
    }
};
