%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "defs.h"
  #include "symtab.h"

  int yyparse(void);
  int yylex(void);
  int yyerror(char *s);
  void warning(char *s);

  extern int yylineno;
  char char_buffer[CHAR_BUFFER_LENGTH];
  int error_count = 0;
  int warning_count = 0;
  int var_num = 0;
  int fun_idx = -1;
  int fcall_idx = -1;
  int var_type;
  int ret_num = 0;
  int block_level = 0;
  int switch_literals[200];
  int case_num = 0;
  int switch_type;
  int should_block_up = 1; // indikator u compound_statement
  
%}

%union {
  int i;
  char *s;
}

%token <i> _TYPE
%token _IF
%token _ELSE
%token _RETURN
%token <s> _ID
%token <s> _INT_NUMBER
%token <s> _UINT_NUMBER
%token _LPAREN
%token _RPAREN
%token _LBRACKET
%token _RBRACKET
%token _ASSIGN
%token _SEMICOLON
%token <i> _AROP
%token <i> _RELOP
%token <i> _LOGOP
%token _DO
%token _WHILE
%token _COMMA
%token _PLUSPLUS
%token _SWITCH
%token _CASE
%token _BREAK
%token _DEFAULT
%token _COLON

%token _FOR
%token _STEP
%token _NEXT
%token <i> _DIRECTION

%type <i> num_exp exp literal function_call argument rel_exp log_exp ass assignments

%nonassoc ONLY_IF
%nonassoc _ELSE

%%

program
  : function_list
      {  
        if(lookup_symbol("main", FUN) == NO_INDEX)
          err("undefined reference to 'main'");
       }
  ;

function_list
  : function
  | function_list function
  ;

function
  : _TYPE _ID
      {
      	block_level = 0;
        fun_idx = lookup_symbol($2, FUN);
        if(fun_idx == NO_INDEX)
          fun_idx = insert_symbol($2, FUN, $1, NO_ATR, NO_ATR);
        else 
          err("redefinition of function '%s'", $2);
      }
    _LPAREN parameter _RPAREN body
      {
        clear_symbols(fun_idx + 1);
        var_num = 0;
        if(get_type(fun_idx)!=VOID && ret_num==0)
        	warn("non-void function '%s' requires return statement", get_name(fun_idx));
        ret_num = 0;
      }
  ;

parameter
  : /* empty */
      { set_atr1(fun_idx, 0); }

  | _TYPE _ID
      {
      	if($1 == VOID)
      		err("parameter must not be of type 'VOID'");
        insert_symbol($2, PAR, $1, 1, NO_ATR);
        set_atr1(fun_idx, 1);
        set_atr2(fun_idx, $1);
      }
  ;

body
  : _LBRACKET variable_list statement_list _RBRACKET
  ;

variable_list
  : /* empty */
  | variable_list variable
  ;

variable
  : _TYPE
  	{ 
  		if($1 == VOID)	
  			err("variable must not be of type 'VOID'");
  		var_type = $1;
  	}
  	variables _SEMICOLON
  ;
  
variables
  : _ID {
  		int idx = lookup_symbol($1, VAR|PAR);
        if(idx == NO_INDEX)
           insert_symbol($1, VAR, var_type, ++var_num, block_level);
        else if(get_atr2(idx) == block_level)
           err("redefinition of '%s'", $1);
        else
        	insert_symbol($1, VAR, var_type, ++var_num, block_level);
        }
  | variables _COMMA _ID
  		{
  		int idx = lookup_symbol($3, VAR|PAR);
        if(idx == NO_INDEX)
           insert_symbol($3, VAR, var_type, ++var_num, block_level);
        else if(get_atr2(idx) == block_level)
           err("redefinition of '%s'", $3);
        else
           insert_symbol($3, VAR, var_type, ++var_num, block_level);
      }
  ;

statement_list
  : /* empty */
  | statement_list statement
  ;

statement
  : compound_statement
  | assignment_statement
  | if_statement
  | return_statement
  | dowhile_statement
  | postincrement_statement
  | basicfor_statement
  | switch_statement
  | for_statement
  ;

for_statement
  : _FOR _LPAREN _TYPE _ID _ASSIGN literal 
  {
  		block_level++;
  		should_block_up = 0;
  		$<i>$ = get_last_element();
  		
  		int idx = lookup_symbol($4, VAR|PAR);
  		
  		if($3 == VOID)
  			err("variable '%s' cannot be void");
  		else if(idx==NO_INDEX)
  			insert_symbol($4, VAR, $3, ++var_num, block_level);
  		else if(get_atr2(idx) == block_level)
  			err("redefinition of '%s'", $4);
  		else
  			insert_symbol($4, VAR, $3, ++var_num, block_level);
  			
  		if($3 != get_type($6))
  			err("incompatible types in for clause");	
  }
  _SEMICOLON rel_exp _SEMICOLON _ID 
  {
  		int idx = lookup_symbol($11, VAR|PAR);
  		
  		if(idx == NO_INDEX)
  			err("'%s' undeclared", $11);
  		else if(idx != lookup_symbol($4, VAR|PAR))
  			err("not same variables in for clause");
  }
  _PLUSPLUS _RPAREN statement
  {
  		should_block_up = 1;

  		clear_symbols($<i>7 + 1);
  		block_level--;
  }
  ;





switch_statement
  : _SWITCH _LPAREN _ID 
  	{
  		int idx = lookup_symbol($3, VAR|PAR);
  	
  		if(idx == NO_INDEX)
  			err("'%s' undeclared", $3);
  		switch_type = get_type(idx);
  		case_num = 0;  		
  	}
  _RPAREN _LBRACKET cases maybedefault _RBRACKET
  ; 
  
cases
  : case
  | cases case
  ;
  
case
  : _CASE literal
  {
  	if(get_type($2)!=switch_type)
  		err("incompatible type in case clause");
  	
  	switch_literals[case_num] = atoi(get_name($2));
  	
  	if(case_num > 0){
  		for(int i=case_num-1; i>=0; --i){
  			if(switch_literals[i] == switch_literals[case_num])
  				err("duplicate switch case");
  		}
  	}
  	
  	case_num++;
  	
  }
  _COLON statement maybebreak
  ;
  
maybebreak
  : /*empty*/
  | _BREAK _SEMICOLON
  ;
  
maybedefault
  : /*empty*/
  | _DEFAULT _COLON statement
  ;
 
basicfor_statement
  : _FOR _ID _ASSIGN literal _DIRECTION literal
  {
  	int idx = lookup_symbol($2, VAR|PAR);
    if(idx == NO_INDEX)
    	err("'%s' undeclared", $2);
  	else if(get_type(idx)!=get_type($4) || get_type(idx)!=get_type($6))
  		err("incompatible types in basic_for statement");
  	else if(($5 == TO && (atoi(get_name($4)))>(atoi(get_name($6)))) || ($5 == DOWNTO && (atoi(get_name($4)))<(atoi(get_name($6)))))
  		err("wrong direction in basic for statement");
  		
  	var_type = get_type(idx);
  }
  maybestep statement _NEXT _ID
  {
  	//$11
  	int idx = lookup_symbol($11, VAR|PAR);
  	if(idx == NO_INDEX)
  		err("'%s' undeclared", $11);
  	else if(idx != lookup_symbol($2, VAR|PAR))
  		err("not the same variable in next clause of basic for (should be '%s')", $2);	
  }
  ;
  
maybestep
  : /*empty*/
  | _STEP literal
  		{
  			if(var_type != get_type($2))
				err("incompatible types in step clause of basic for statement");
  		}
  ;
  
postincrement_statement
  : _ID _PLUSPLUS _SEMICOLON
  		{
  			if(lookup_symbol($1, VAR|PAR)==NO_INDEX)
  				err("invalid lvalue '%s' in postincrement operator", $1);
  		}
  ;
  
compound_statement
  : _LBRACKET 
  {
  	$<i>$ = should_block_up;
  	if(should_block_up)
  		block_level++;
  	
  	should_block_up = 1;
  }
  {
  	$<i>$ =  get_last_element();
  }
  variable_list statement_list
  {
  	clear_symbols($<i>3 + 1);
  	if($<i>2 == 1)
  		block_level--;
  }
  _RBRACKET
  ;
  
assignment_statement
  : assignments num_exp _SEMICOLON
  	{
  		if(get_type($1)!=get_type($2))
  			err("incompatible types in assignment");
  	}
  ;
  
assignments
  : ass
  | assignments ass
  		{
  			if(get_type($1)!=get_type($2))
  				err("incompatible types in assignment");
  		}
  ;

ass
  : _ID _ASSIGN
  	{
  		$$ = lookup_symbol($1, VAR|PAR);
  		if($$ == NO_INDEX)
  			err("'%s' undeclared", $1);
  	}
  ;

num_exp
  : exp
  | num_exp _AROP exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: arithmetic operation");
      }
  ;

exp
  : literal
  | _ID
      {
        $$ = lookup_symbol($1, VAR|PAR);
        if($$ == NO_INDEX)
          err("'%s' undeclared", $1);
      }
  | _ID _PLUSPLUS
  		{
  			$$ = lookup_symbol($1, VAR|PAR);
  			if($$ == NO_INDEX)
  				err("'%s' undeclared", $1);
  		}
  | function_call
  | _LPAREN num_exp _RPAREN
      { $$ = $2; }
  ;

literal
  : _INT_NUMBER
      { $$ = insert_literal($1, INT); }

  | _UINT_NUMBER
      { $$ = insert_literal($1, UINT); }
  ;

function_call
  : _ID 
      {
        fcall_idx = lookup_symbol($1, FUN);
        if(fcall_idx == NO_INDEX)
          err("'%s' is not a function", $1);
      }
    _LPAREN argument _RPAREN
      {
        if(get_atr1(fcall_idx) != $4)
          err("wrong number of args to function '%s'", 
              get_name(fcall_idx));
        set_type(FUN_REG, get_type(fcall_idx));
        $$ = FUN_REG;
      }
  ;

argument
  : /* empty */
    { $$ = 0; }

  | num_exp
    { 
      if(get_atr2(fcall_idx) != get_type($1))
        err("incompatible type for argument in '%s'",
            get_name(fcall_idx));
      $$ = 1;
    }
  ;

if_statement
  : if_part %prec ONLY_IF
  | if_part _ELSE statement
  ;

if_part
  : _IF _LPAREN log_exp _RPAREN statement
  ;
  
log_exp
  : rel_exp
  | log_exp _LOGOP rel_exp
  	  {
        if(get_type($1) != get_type($3))
          err("invalid operands: logical operator");
      }
  ;

rel_exp
  : num_exp _RELOP num_exp
      {
        if(get_type($1) != get_type($3))
          err("invalid operands: relational operator");
      }
  | _LPAREN rel_exp _RPAREN
  	  {
  	  	$$ = $2;
  	  }
  ;

return_statement
  : _RETURN _SEMICOLON
  		{
  			ret_num++;
  			if(get_type(fun_idx)!=VOID)
  				warn("non-void function '%s' must return something", get_name(fun_idx));
  		}
  | _RETURN num_exp _SEMICOLON
      {
      	ret_num++;
      	if(get_type(fun_idx) == VOID)
      		err("void function must not return anything");
        else if(get_type(fun_idx) != get_type($2))
          err("incompatible types in return");
      }
  ;
  
dowhile_statement
  : _DO statement _WHILE _LPAREN log_exp _RPAREN _SEMICOLON
  ;

%%

int yyerror(char *s) {
  fprintf(stderr, "\nline %d: ERROR: %s", yylineno, s);
  error_count++;
  return 0;
}

void warning(char *s) {
  fprintf(stderr, "\nline %d: WARNING: %s", yylineno, s);
  warning_count++;
}

int main() {
  int synerr;
  init_symtab();

  synerr = yyparse();

  clear_symtab();
  
  if(warning_count)
    printf("\n%d warning(s).\n", warning_count);

  if(error_count)
    printf("\n%d error(s).\n", error_count);

  if(synerr)
    return -1; //syntax error
  else
    return error_count; //semantic errors
}

