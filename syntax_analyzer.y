%{
#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table *table;  // Global symbol table
string current_type;  // Track current declaration type
vector<string> current_params;  // Track function parameters
vector<string> current_args;    // Track function call arguments

int lines = 1;
int error_count = 0;
ofstream outlog;
ofstream errorout;

// Helper functions for semantic analysis
void semantic_error(string message) {
    error_count++;
    errorout << "Error at line " << lines << ": " << message << endl;
    outlog << "Error at line " << lines << ": " << message << endl;
}

void semantic_warning(string message) {
    errorout << "Warning at line " << lines << ": " << message << endl;
    outlog << "Warning at line " << lines << ": " << message << endl;
}

// Type checking helper functions
bool is_int_type(string type) {
    return type == "int";
}

bool is_float_type(string type) {
    return type == "float";
}

bool is_void_type(string type) {
    return type == "void";
}

bool is_numeric_type(string type) {
    return is_int_type(type) || is_float_type(type);
}

void yyerror(char *s)
{
    outlog << "At line " << lines << " " << s << endl << endl;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
{
    outlog << "At line no: " << lines << " start : program " << endl << endl;
    outlog << "Symbol Table" << endl << endl;
    table->print_all_scopes(outlog);
}
;

program : program unit
{
    outlog << "At line no: " << lines << " program : program unit " << endl << endl;
    outlog << $1->get_name() + "\n" + $2->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + "\n" + $2->get_name(), "program");
}
| unit
{
    outlog << "At line no: " << lines << " program : unit " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "program");
}
;

unit : var_declaration
{
    outlog << "At line no: " << lines << " unit : var_declaration " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "unit");
}
| func_definition
{
    outlog << "At line no: " << lines << " unit : func_definition " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "unit");
}
;

func_definition : type_specifier ID LPAREN parameter_list RPAREN
{
    // Check if function already exists
    symbol_info* existing = table->lookup_current_scope($2->get_name());
    if (existing != NULL) {
        if (existing->is_function()) {
            // Check if function signature matches
            if (existing->get_data_type() != $1->get_name() ||
                existing->get_param_types() != current_params) {
                semantic_error("Function '" + $2->get_name() + "' redeclared with different return type or parameters");
            }
        } else {
            semantic_error("'" + $2->get_name() + "' redeclared as a function");
        }
    } else {
        // Store function info before entering new scope
        table->insert_function($2->get_name(), $1->get_name(), current_params);
    }

    table->enter_scope();
    table->log_enter_scope(outlog);

    // Insert parameters into new scope
    for(size_t i = 0; i < current_params.size(); i++) {
        // Check for void parameters
        if (current_params[i] == "void" && current_params.size() > 1) {
            semantic_error("Void cannot be a parameter type except for a function with a single void parameter");
        } else {
            table->insert_variable($2->get_name(), current_params[i]);
        }
    }
}
compound_statement
{
    outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement " << endl << endl;
    outlog << $1->get_name() << " " << $2->get_name() << "(" << $4->get_name() << ")\n" << $7->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ")\n" + $7->get_name(), "func_def");

    table->log_exit_scope(outlog);
    table->exit_scope();
}
| type_specifier ID LPAREN RPAREN
{
    // Check if function already exists
    symbol_info* existing = table->lookup_current_scope($2->get_name());
    if (existing != NULL) {
        if (existing->is_function()) {
            // Check if function signature matches
            if (existing->get_data_type() != $1->get_name() ||
                !existing->get_param_types().empty()) {
                semantic_error("Function '" + $2->get_name() + "' redeclared with different return type or parameters");
            }
        } else {
            semantic_error("'" + $2->get_name() + "' redeclared as a function");
        }
    } else {
        // Store function info before entering new scope
        table->insert_function($2->get_name(), $1->get_name(), vector<string>());
    }

    table->enter_scope();
    table->log_enter_scope(outlog);
}
compound_statement
{
    outlog << "At line no: " << lines << " func_definition : type_specifier ID LPAREN RPAREN compound_statement " << endl << endl;
    outlog << $1->get_name() << " " << $2->get_name() << "()\n" << $6->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + " " + $2->get_name() + "()\n" + $6->get_name(), "func_def");

    table->log_exit_scope(outlog);
    table->exit_scope();
}
;

parameter_list : parameter_list COMMA type_specifier ID
{
    outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier ID " << endl << endl;
    outlog << $1->get_name() << "," << $3->get_name() << " " << $4->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + "," + $3->get_name() + " " + $4->get_name(), "param_list");
    current_params.push_back($3->get_name());
}
| parameter_list COMMA type_specifier
{
    outlog << "At line no: " << lines << " parameter_list : parameter_list COMMA type_specifier " << endl << endl;
    outlog << $1->get_name() << "," << $3->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "param_list");
    current_params.push_back($3->get_name());
}
| type_specifier ID
{
    outlog << "At line no: " << lines << " parameter_list : type_specifier ID " << endl << endl;
    outlog << $1->get_name() << " " << $2->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + " " + $2->get_name(), "param_list");
    current_params.clear();
    current_params.push_back($1->get_name());
}
| type_specifier
{
    outlog << "At line no: " << lines << " parameter_list : type_specifier " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "param_list");
    current_params.clear();
    current_params.push_back($1->get_name());
}
;

compound_statement : LCURL
{
    table->enter_scope();
    table->log_enter_scope(outlog);
}
statements RCURL
{
    outlog << "At line no: " << lines << " compound_statement : LCURL statements RCURL " << endl << endl;
    outlog << "{\n" << $3->get_name() << "\n}" << endl << endl;
    $$ = new symbol_info("{\n" + $3->get_name() + "\n}", "comp_stmnt");

    table->log_exit_scope(outlog);
    table->exit_scope();
}
| LCURL RCURL
{
    outlog << "At line no: " << lines << " compound_statement : LCURL RCURL " << endl << endl;
    outlog << "{\n}" << endl << endl;
    $$ = new symbol_info("{\n}", "comp_stmnt");
}
;

var_declaration : type_specifier declaration_list SEMICOLON
{
    outlog << "At line no: " << lines << " var_declaration : type_specifier declaration_list SEMICOLON " << endl << endl;
    outlog << $1->get_name() << " " << $2->get_name() << ";" << endl << endl;
    $$ = new symbol_info($1->get_name() + " " + $2->get_name() + ";", "var_dec");
    current_type = $1->get_name();
}
;

type_specifier : INT
{
    outlog << "At line no: " << lines << " type_specifier : INT " << endl << endl;
    outlog << "int" << endl << endl;
    $$ = new symbol_info("int", "type");
    current_type = "int";
}
| FLOAT
{
    outlog << "At line no: " << lines << " type_specifier : FLOAT " << endl << endl;
    outlog << "float" << endl << endl;
    $$ = new symbol_info("float", "type");
    current_type = "float";
}
| VOID
{
    outlog << "At line no: " << lines << " type_specifier : VOID " << endl << endl;
    outlog << "void" << endl << endl;
    $$ = new symbol_info("void", "type");
    current_type = "void";
}
;

declaration_list : declaration_list COMMA ID
{
    outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID " << endl << endl;
    outlog << $1->get_name() << "," << $3->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "decl_list");

    // Check if variable already exists in current scope
    if (table->lookup_current_scope($3->get_name()) != NULL) {
        semantic_error("Multiple declaration of '" + $3->get_name() + "' in the same scope");
    } else {
        table->insert_variable($3->get_name(), current_type);
    }
}
| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
{
    outlog << "At line no: " << lines << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
    outlog << $1->get_name() << "," << $3->get_name() << "[" << $5->get_name() << "]" << endl << endl;
    $$ = new symbol_info($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]", "decl_list");

    // Check if array already exists in current scope
    if (table->lookup_current_scope($3->get_name()) != NULL) {
        semantic_error("Multiple declaration of '" + $3->get_name() + "' in the same scope");
    } else {
        // Check if array size is valid
        int size = stoi($5->get_name());
        if (size <= 0) {
            semantic_error("Array size must be a positive integer");
        } else {
            table->insert_array($3->get_name(), current_type, size);
        }
    }
}
| ID
{
    outlog << "At line no: " << lines << " declaration_list : ID " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "decl_list");

    // Check if variable already exists in current scope
    if (table->lookup_current_scope($1->get_name()) != NULL) {
        semantic_error("Multiple declaration of '" + $1->get_name() + "' in the same scope");
    } else {
        table->insert_variable($1->get_name(), current_type);
    }
}
| ID LTHIRD CONST_INT RTHIRD
{
    outlog << "At line no: " << lines << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
    outlog << $1->get_name() << "[" << $3->get_name() << "]" << endl << endl;
    $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "decl_list");

    // Check if array already exists in current scope
    if (table->lookup_current_scope($1->get_name()) != NULL) {
        semantic_error("Multiple declaration of '" + $1->get_name() + "' in the same scope");
    } else {
        // Check if array size is valid
        int size = stoi($3->get_name());
        if (size <= 0) {
            semantic_error("Array size must be a positive integer");
        } else {
            table->insert_array($1->get_name(), current_type, size);
        }
    }
}
;

statements : statement
{
    outlog << "At line no: " << lines << " statements : statement " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "stmnts");
}
| statements statement
{
    outlog << "At line no: " << lines << " statements : statements statement " << endl << endl;
    outlog << $1->get_name() << "\n" << $2->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + "\n" + $2->get_name(), "stmnts");
}
;

statement : var_declaration
{
    outlog << "At line no: " << lines << " statement : var_declaration " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "stmnt");
}
| expression_statement
{
    outlog << "At line no: " << lines << " statement : expression_statement " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "stmnt");
}
| compound_statement
{
    outlog << "At line no: " << lines << " statement : compound_statement " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "stmnt");
}
| FOR LPAREN expression_statement expression_statement expression RPAREN statement
{
    outlog << "At line no: " << lines << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement " << endl << endl;
    outlog << "for(" << $3->get_name() << $4->get_name() << $5->get_name() << ")\n" << $7->get_name() << endl << endl;
    $$ = new symbol_info("for(" + $3->get_name() + $4->get_name() + $5->get_name() + ")\n" + $7->get_name(), "stmnt");
}
| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
{
    outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement " << endl << endl;
    outlog << "if(" << $3->get_name() << ")\n" << $5->get_name() << endl << endl;
    $$ = new symbol_info("if(" + $3->get_name() + ")\n" + $5->get_name(), "stmnt");
}
| IF LPAREN expression RPAREN statement ELSE statement
{
    outlog << "At line no: " << lines << " statement : IF LPAREN expression RPAREN statement ELSE statement " << endl << endl;
    outlog << "if(" << $3->get_name() << ")\n" << $5->get_name() << "\nelse\n" << $7->get_name() << endl << endl;
    $$ = new symbol_info("if(" + $3->get_name() + ")\n" + $5->get_name() + "\nelse\n" + $7->get_name(), "stmnt");
}
| WHILE LPAREN expression RPAREN statement
{
    outlog << "At line no: " << lines << " statement : WHILE LPAREN expression RPAREN statement " << endl << endl;
    outlog << "while(" << $3->get_name() << ")\n" << $5->get_name() << endl << endl;
    $$ = new symbol_info("while(" + $3->get_name() + ")\n" + $5->get_name(), "stmnt");
}
| PRINTLN LPAREN ID RPAREN SEMICOLON
{
    outlog << "At line no: " << lines << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON " << endl << endl;
    outlog << "printf(" << $3->get_name() << ");" << endl << endl;
    $$ = new symbol_info("printf(" + $3->get_name() + ");", "stmnt");
}
| RETURN expression SEMICOLON
{
    outlog << "At line no: " << lines << " statement : RETURN expression SEMICOLON " << endl << endl;
    outlog << "return " << $2->get_name() << ";" << endl << endl;

    // TODO: Check return type against function return type
    // This would require tracking the current function's return type

    $$ = new symbol_info("return " + $2->get_name() + ";", "stmnt");
}
;

expression_statement : SEMICOLON
{
    outlog << "At line no: " << lines << " expression_statement : SEMICOLON " << endl << endl;
    outlog << ";" << endl << endl;
    $$ = new symbol_info(";", "expr_stmt");
}
| expression SEMICOLON
{
    outlog << "At line no: " << lines << " expression_statement : expression SEMICOLON " << endl << endl;
    outlog << $1->get_name() << ";" << endl << endl;
    $$ = new symbol_info($1->get_name() + ";", "expr_stmt");
}
;

variable : ID
{
    outlog << "At line no: " << lines << " variable : ID " << endl << endl;
    outlog << $1->get_name() << endl << endl;

    // Check if the variable is declared
    symbol_info* symbol = table->lookup_symbol($1->get_name());
    if (symbol == NULL) {
        semantic_error("Undeclared variable '" + $1->get_name() + "'");
        $$ = new symbol_info($1->get_name(), "varbl");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else {
        // Check if it's an array being used without index
        if (symbol->is_array()) {
            semantic_error("Array '" + $1->get_name() + "' must be accessed with an index");
            $$ = new symbol_info($1->get_name(), "varbl");
            $$->set_data_type(symbol->get_data_type());
            $$->set_is_error(true);
        } else if (symbol->is_function()) {
            semantic_error("Function '" + $1->get_name() + "' cannot be used as a variable");
            $$ = new symbol_info($1->get_name(), "varbl");
            $$->set_data_type("error");
            $$->set_is_error(true);
        } else {
            // Valid variable
            $$ = new symbol_info($1->get_name(), "varbl");
            $$->set_data_type(symbol->get_data_type());
        }
    }
}
| ID LTHIRD expression RTHIRD
{
    outlog << "At line no: " << lines << " variable : ID LTHIRD expression RTHIRD " << endl << endl;
    outlog << $1->get_name() << "[" << $3->get_name() << "]" << endl << endl;

    // Check if the array is declared
    symbol_info* symbol = table->lookup_symbol($1->get_name());
    if (symbol == NULL) {
        semantic_error("Undeclared array '" + $1->get_name() + "'");
        $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "varbl");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else {
        // Check if it's a non-array being used with index
        if (!symbol->is_array()) {
            semantic_error("Non-array variable '" + $1->get_name() + "' cannot be accessed with index");
            $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "varbl");
            $$->set_data_type(symbol->get_data_type());
            $$->set_is_error(true);
        } else {
            // Check if the index is an integer
            if (!$3->get_data_type().empty() && !is_int_type($3->get_data_type())) {
                semantic_error("Array index must be an integer");
                $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "varbl");
                $$->set_data_type(symbol->get_data_type());
                $$->set_is_error(true);
            } else {
                // Valid array access
                $$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "varbl");
                $$->set_data_type(symbol->get_data_type());
            }
        }
    }
}
;

expression : logic_expression
{
    outlog << "At line no: " << lines << " expression : logic_expression " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "expr");
    $$->set_data_type($1->get_data_type());
}
| variable ASSIGNOP logic_expression
{
    outlog << "At line no: " << lines << " expression : variable ASSIGNOP logic_expression " << endl << endl;
    outlog << $1->get_name() << "=" << $3->get_name() << endl << endl;

    // Check for assignment compatibility
    if ($1->get_is_error() || $3->get_is_error()) {
        // If either side has an error, propagate it
        $$ = new symbol_info($1->get_name() + "=" + $3->get_name(), "expr");
        $$->set_data_type($1->get_data_type());
        $$->set_is_error(true);
    } else if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
        semantic_error("Void cannot be used in an expression");
        $$ = new symbol_info($1->get_name() + "=" + $3->get_name(), "expr");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else if (!is_numeric_type($1->get_data_type()) || !is_numeric_type($3->get_data_type())) {
        semantic_error("Type mismatch in assignment");
        $$ = new symbol_info($1->get_name() + "=" + $3->get_name(), "expr");
        $$->set_data_type($1->get_data_type());
        $$->set_is_error(true);
    } else {
        // Type conversion check
        if (is_int_type($1->get_data_type()) && is_float_type($3->get_data_type())) {
            semantic_warning("Possible loss of precision in assignment of float to int");
        }

        $$ = new symbol_info($1->get_name() + "=" + $3->get_name(), "expr");
        $$->set_data_type($1->get_data_type());
    }
}
;

logic_expression : rel_expression
{
    outlog << "At line no: " << lines << " logic_expression : rel_expression " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "lgc_expr");
    $$->set_data_type($1->get_data_type());
}
| rel_expression LOGICOP rel_expression
{
    outlog << "At line no: " << lines << " logic_expression : rel_expression LOGICOP rel_expression " << endl << endl;
    outlog << $1->get_name() << $2->get_name() << $3->get_name() << endl << endl;

    // Check for logical operator compatibility
    if ($1->get_is_error() || $3->get_is_error()) {
        // If either side has an error, propagate it
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "lgc_expr");
        $$->set_data_type("int"); // Result of logical operation is always int
        $$->set_is_error(true);
    } else if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
        semantic_error("Void cannot be used in a logical expression");
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "lgc_expr");
        $$->set_data_type("int"); // Result of logical operation is always int
        $$->set_is_error(true);
    } else if (!is_numeric_type($1->get_data_type()) || !is_numeric_type($3->get_data_type())) {
        semantic_error("Non-numeric operands in logical expression");
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "lgc_expr");
        $$->set_data_type("int"); // Result of logical operation is always int
        $$->set_is_error(true);
    } else {
        // Valid logical operation
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "lgc_expr");
        $$->set_data_type("int"); // Result of logical operation is always int
    }
}
;

rel_expression : simple_expression
{
    outlog << "At line no: " << lines << " rel_expression : simple_expression " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "rel_expr");
    $$->set_data_type($1->get_data_type());
}
| simple_expression RELOP simple_expression
{
    outlog << "At line no: " << lines << " rel_expression : simple_expression RELOP simple_expression " << endl << endl;
    outlog << $1->get_name() << $2->get_name() << $3->get_name() << endl << endl;

    // Check for relational operator compatibility
    if ($1->get_is_error() || $3->get_is_error()) {
        // If either side has an error, propagate it
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "rel_expr");
        $$->set_data_type("int"); // Result of relational operation is always int
        $$->set_is_error(true);
    } else if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
        semantic_error("Void cannot be used in a relational expression");
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "rel_expr");
        $$->set_data_type("int"); // Result of relational operation is always int
        $$->set_is_error(true);
    } else if (!is_numeric_type($1->get_data_type()) || !is_numeric_type($3->get_data_type())) {
        semantic_error("Non-numeric operands in relational expression");
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "rel_expr");
        $$->set_data_type("int"); // Result of relational operation is always int
        $$->set_is_error(true);
    } else {
        // Valid relational operation
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "rel_expr");
        $$->set_data_type("int"); // Result of relational operation is always int
    }
}
;

simple_expression : term
{
    outlog << "At line no: " << lines << " simple_expression : term " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "simp_expr");
    $$->set_data_type($1->get_data_type());
}
| simple_expression ADDOP term
{
    outlog << "At line no: " << lines << " simple_expression : simple_expression ADDOP term " << endl << endl;
    outlog << $1->get_name() << $2->get_name() << $3->get_name() << endl << endl;

    // Check for arithmetic operator compatibility
    if ($1->get_is_error() || $3->get_is_error()) {
        // If either side has an error, propagate it
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "simp_expr");
        $$->set_is_error(true);

        // Determine result type (prefer float over int)
        if (is_float_type($1->get_data_type()) || is_float_type($3->get_data_type())) {
            $$->set_data_type("float");
        } else {
            $$->set_data_type("int");
        }
    } else if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
        semantic_error("Void cannot be used in an arithmetic expression");
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "simp_expr");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else if (!is_numeric_type($1->get_data_type()) || !is_numeric_type($3->get_data_type())) {
        semantic_error("Non-numeric operands in arithmetic expression");
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "simp_expr");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else {
        // Valid arithmetic operation
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "simp_expr");

        // Determine result type (prefer float over int)
        if (is_float_type($1->get_data_type()) || is_float_type($3->get_data_type())) {
            $$->set_data_type("float");
        } else {
            $$->set_data_type("int");
        }
    }
}
;

term : unary_expression
{
    outlog << "At line no: " << lines << " term : unary_expression " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "term");
    $$->set_data_type($1->get_data_type());
}
| term MULOP unary_expression
{
    outlog << "At line no: " << lines << " term : term MULOP unary_expression " << endl << endl;
    outlog << $1->get_name() << $2->get_name() << $3->get_name() << endl << endl;

    // Check for multiplication operator compatibility
    if ($1->get_is_error() || $3->get_is_error()) {
        // If either side has an error, propagate it
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");
        $$->set_is_error(true);

        // Determine result type (prefer float over int)
        if (is_float_type($1->get_data_type()) || is_float_type($3->get_data_type())) {
            $$->set_data_type("float");
        } else {
            $$->set_data_type("int");
        }
    } else if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
        semantic_error("Void cannot be used in a multiplication expression");
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else if (!is_numeric_type($1->get_data_type()) || !is_numeric_type($3->get_data_type())) {
        semantic_error("Non-numeric operands in multiplication expression");
        $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else {
        // Check for modulus operator
        if ($2->get_name() == "%") {
            // Both operands must be integers for modulus
            if (!is_int_type($1->get_data_type()) || !is_int_type($3->get_data_type())) {
                semantic_error("Both operands of modulus must be integers");
                $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");
                $$->set_data_type("int"); // Result of modulus is always int
                $$->set_is_error(true);
            } else {
                // Check for modulus by zero
                if ($3->get_name() == "0") {
                    semantic_error("Modulus by zero");
                    $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");
                    $$->set_data_type("int");
                    $$->set_is_error(true);
                } else {
                    $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");
                    $$->set_data_type("int"); // Result of modulus is always int
                }
            }
        } else if ($2->get_name() == "/") {
            // Check for division by zero
            if ($3->get_name() == "0") {
                semantic_error("Division by zero");
                $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");
                $$->set_is_error(true);

                // Determine result type (prefer float over int)
                if (is_float_type($1->get_data_type()) || is_float_type($3->get_data_type())) {
                    $$->set_data_type("float");
                } else {
                    $$->set_data_type("int");
                }
            } else {
                // Valid division
                $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");

                // Determine result type (prefer float over int)
                if (is_float_type($1->get_data_type()) || is_float_type($3->get_data_type())) {
                    $$->set_data_type("float");
                } else {
                    $$->set_data_type("int");
                }
            }
        } else {
            // Valid multiplication or other operation
            $$ = new symbol_info($1->get_name() + $2->get_name() + $3->get_name(), "term");

            // Determine result type (prefer float over int)
            if (is_float_type($1->get_data_type()) || is_float_type($3->get_data_type())) {
                $$->set_data_type("float");
            } else {
                $$->set_data_type("int");
            }
        }
    }
}
;

unary_expression : ADDOP unary_expression
{
    outlog << "At line no: " << lines << " unary_expression : ADDOP unary_expression " << endl << endl;
    outlog << $1->get_name() << $2->get_name() << endl << endl;

    // Check for unary arithmetic operator compatibility
    if ($2->get_is_error()) {
        // If operand has an error, propagate it
        $$ = new symbol_info($1->get_name() + $2->get_name(), "un_expr");
        $$->set_data_type($2->get_data_type());
        $$->set_is_error(true);
    } else if ($2->get_data_type() == "void") {
        semantic_error("Void cannot be used in an arithmetic expression");
        $$ = new symbol_info($1->get_name() + $2->get_name(), "un_expr");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else if (!is_numeric_type($2->get_data_type())) {
        semantic_error("Non-numeric operand in unary arithmetic expression");
        $$ = new symbol_info($1->get_name() + $2->get_name(), "un_expr");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else {
        // Valid unary arithmetic operation
        $$ = new symbol_info($1->get_name() + $2->get_name(), "un_expr");
        $$->set_data_type($2->get_data_type()); // Preserve operand type
    }
}
| NOT unary_expression
{
    outlog << "At line no: " << lines << " unary_expression : NOT unary_expression " << endl << endl;
    outlog << "!" << $2->get_name() << endl << endl;

    // Check for logical NOT operator compatibility
    if ($2->get_is_error()) {
        // If operand has an error, propagate it
        $$ = new symbol_info("!" + $2->get_name(), "un_expr");
        $$->set_data_type("int"); // Result of logical NOT is always int
        $$->set_is_error(true);
    } else if ($2->get_data_type() == "void") {
        semantic_error("Void cannot be used in a logical expression");
        $$ = new symbol_info("!" + $2->get_name(), "un_expr");
        $$->set_data_type("int"); // Result of logical NOT is always int
        $$->set_is_error(true);
    } else if (!is_numeric_type($2->get_data_type())) {
        semantic_error("Non-numeric operand in logical NOT expression");
        $$ = new symbol_info("!" + $2->get_name(), "un_expr");
        $$->set_data_type("int"); // Result of logical NOT is always int
        $$->set_is_error(true);
    } else {
        // Valid logical NOT operation
        $$ = new symbol_info("!" + $2->get_name(), "un_expr");
        $$->set_data_type("int"); // Result of logical NOT is always int
    }
}
| factor
{
    outlog << "At line no: " << lines << " unary_expression : factor " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "un_expr");
    $$->set_data_type($1->get_data_type());
}
;

factor : variable
{
    outlog << "At line no: " << lines << " factor : variable " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "fctr");
    $$->set_data_type($1->get_data_type());
    $$->set_is_error($1->get_is_error());
}
| ID LPAREN argument_list RPAREN
{
    outlog << "At line no: " << lines << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
    outlog << $1->get_name() << "(" << $3->get_name() << ")" << endl << endl;

    // Check if the function is declared
    symbol_info* func = table->lookup_symbol($1->get_name());
    if (func == NULL) {
        semantic_error("Undeclared function '" + $1->get_name() + "'");
        $$ = new symbol_info($1->get_name() + "(" + $3->get_name() + ")", "fctr");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else if (!func->is_function()) {
        semantic_error("'" + $1->get_name() + "' is not a function");
        $$ = new symbol_info($1->get_name() + "(" + $3->get_name() + ")", "fctr");
        $$->set_data_type("error");
        $$->set_is_error(true);
    } else {
        // Check if the function is void and used in an expression
        if (func->get_data_type() == "void") {
            semantic_error("Void function '" + $1->get_name() + "' cannot be used in an expression");
            $$ = new symbol_info($1->get_name() + "(" + $3->get_name() + ")", "fctr");
            $$->set_data_type("error");
            $$->set_is_error(true);
        } else {
            // Check argument count
            if (current_args.size() != func->get_param_types().size()) {
                semantic_error("Function '" + $1->get_name() + "' called with wrong number of arguments");
                $$ = new symbol_info($1->get_name() + "(" + $3->get_name() + ")", "fctr");
                $$->set_data_type(func->get_data_type());
                $$->set_is_error(true);
            } else {
                // Check argument types
                bool type_mismatch = false;
                for (size_t i = 0; i < current_args.size(); i++) {
                    if (!is_numeric_type(current_args[i]) || !is_numeric_type(func->get_param_types()[i])) {
                        type_mismatch = true;
                        break;
                    }

                    // Check for float to int conversion
                    if (is_float_type(current_args[i]) && is_int_type(func->get_param_types()[i])) {
                        semantic_warning("Possible loss of precision in argument " + to_string(i+1) + " of call to '" + $1->get_name() + "'");
                    }
                }

                if (type_mismatch) {
                    semantic_error("Function '" + $1->get_name() + "' called with incompatible argument types");
                    $$ = new symbol_info($1->get_name() + "(" + $3->get_name() + ")", "fctr");
                    $$->set_data_type(func->get_data_type());
                    $$->set_is_error(true);
                } else {
                    // Valid function call
                    $$ = new symbol_info($1->get_name() + "(" + $3->get_name() + ")", "fctr");
                    $$->set_data_type(func->get_data_type());
                }
            }
        }
    }

    // Clear the argument list for the next function call
    current_args.clear();
}
| LPAREN expression RPAREN
{
    outlog << "At line no: " << lines << " factor : LPAREN expression RPAREN " << endl << endl;
    outlog << "(" << $2->get_name() << ")" << endl << endl;
    $$ = new symbol_info("(" + $2->get_name() + ")", "fctr");
    $$->set_data_type($2->get_data_type());
    $$->set_is_error($2->get_is_error());
}
| CONST_INT
{
    outlog << "At line no: " << lines << " factor : CONST_INT " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "fctr");
    $$->set_data_type("int");
}
| CONST_FLOAT
{
    outlog << "At line no: " << lines << " factor : CONST_FLOAT " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "fctr");
    $$->set_data_type("float");
}
| variable INCOP
{
    outlog << "At line no: " << lines << " factor : variable INCOP " << endl << endl;
    outlog << $1->get_name() << "++" << endl << endl;

    // Check if the variable is numeric
    if ($1->get_is_error()) {
        $$ = new symbol_info($1->get_name() + "++", "fctr");
        $$->set_data_type($1->get_data_type());
        $$->set_is_error(true);
    } else if (!is_numeric_type($1->get_data_type())) {
        semantic_error("Operand of increment operator must be a numeric type");
        $$ = new symbol_info($1->get_name() + "++", "fctr");
        $$->set_data_type($1->get_data_type());
        $$->set_is_error(true);
    } else {
        $$ = new symbol_info($1->get_name() + "++", "fctr");
        $$->set_data_type($1->get_data_type());
    }
}
| variable DECOP
{
    outlog << "At line no: " << lines << " factor : variable DECOP " << endl << endl;
    outlog << $1->get_name() << "--" << endl << endl;

    // Check if the variable is numeric
    if ($1->get_is_error()) {
        $$ = new symbol_info($1->get_name() + "--", "fctr");
        $$->set_data_type($1->get_data_type());
        $$->set_is_error(true);
    } else if (!is_numeric_type($1->get_data_type())) {
        semantic_error("Operand of decrement operator must be a numeric type");
        $$ = new symbol_info($1->get_name() + "--", "fctr");
        $$->set_data_type($1->get_data_type());
        $$->set_is_error(true);
    } else {
        $$ = new symbol_info($1->get_name() + "--", "fctr");
        $$->set_data_type($1->get_data_type());
    }
}
;

argument_list : arguments
{
    outlog << "At line no: " << lines << " argument_list : arguments " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "arg_list");
}
|
{
    outlog << "At line no: " << lines << " argument_list :  " << endl << endl;
    outlog << "" << endl << endl;
    $$ = new symbol_info("", "arg_list");
    // Empty argument list is valid
    current_args.clear();
}
;

arguments : arguments COMMA logic_expression
{
    outlog << "At line no: " << lines << " arguments : arguments COMMA logic_expression " << endl << endl;
    outlog << $1->get_name() << "," << $3->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name() + "," + $3->get_name(), "arg");

    // Add the argument type to the list
    current_args.push_back($3->get_data_type());
}
| logic_expression
{
    outlog << "At line no: " << lines << " arguments : logic_expression " << endl << endl;
    outlog << $1->get_name() << endl << endl;
    $$ = new symbol_info($1->get_name(), "arg");

    // Initialize the argument list with the first argument
    current_args.clear();
    current_args.push_back($1->get_data_type());
}
;

%%

int main(int argc, char *argv[])
{
    if(argc != 2) {
        cout << "Please input file name" << endl;
        return 0;
    }

    yyin = fopen(argv[1], "r");
    outlog.open("21301559_log.txt", ios::trunc);
    errorout.open("21301559_error.txt", ios::trunc);

    if(yyin == NULL) {
        cout << "Couldn't open file" << endl;
        return 0;
    }

    // Create global symbol table with 101 buckets
    table = new symbol_table(101);

    yyparse();

    outlog << endl << "Total lines: " << lines << endl;
    outlog << "Total errors: " << error_count << endl;

    errorout << "Total errors: " << error_count << endl;

    delete table;
    outlog.close();
    errorout.close();
    fclose(yyin);

    return 0;
}
