/**************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include <memory/vaddr.h>


enum {
  TK_NOTYPE = 256, TK_DEREF, TK_EQ, TK_HEX, TK_DEC, TK_LT, TK_GT, TK_LE, TK_GE, TK_AND

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */
  {"0[xX][0-9a-fA-F]+", TK_HEX},    //hex
  {"[0-9]+u?", TK_DEC},             // dec
  {" +", TK_NOTYPE},                // spaces
  {"\\+", '+'},                     // plus
  {"-", '-'},                       // minus
  {"\\*", '*'},                     // times
  {"/", '/'},                       // divide
  {"\\(", '('},                     // (
  {")", ')'},                       // )
  {"==", TK_EQ},                    // equal
  {"<=", TK_LE},                    // less or equal
  {">=", TK_GE},                    // greater or equal
  {">", TK_LT},                     // greater than
  {"<", TK_GT},                     // less than
  {"&&", TK_AND},                   // logic ANDi
  {"\\$[a-zA-Z]{1,2}[0-9]{0,2}", '$'},                       // get reg value
};

#define NR_REGEX ARRLEN(rules)

int prec(int type){
    switch(type){
        case TK_AND:    return 1;   // &&
        case TK_EQ:     return 2;   // ==
        case TK_LT:                 // <
        case TK_GT:                 // >
        case TK_LE:                 // <=
        case TK_GE:     return 3;   // >=
        case '+':   
        case '-':       return 4;
        case '*':
        case '/':       return 5;
        case TK_DEREF:  return 6;
        case '$':       return 7;
        default:        return 100;
    }
}

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0){ 
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[65536] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
    int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;
  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;
        if(substr_len > 32){
            panic("Too long substr_len: %d", substr_len);
        }
        //Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
        //    i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */
        
        switch (rules[i].token_type) {
          //default: TODO();
          case TK_HEX:  tokens[nr_token].type = TK_HEX;
                        strncpy(tokens[nr_token].str, substr_start, substr_len%32);
                        tokens[nr_token].str[substr_len%32] = '\0';
                        nr_token ++;
                        break;
          case TK_DEC:  tokens[nr_token].type = TK_DEC;
                        if(substr_start[substr_len-1] == 'u')
                            substr_len --;
                        strncpy(tokens[nr_token].str, substr_start, substr_len%32);
                        tokens[nr_token].str[substr_len%32] = '\0';
                        nr_token ++;
                        break;
          case TK_NOTYPE: break;
          case '+':     tokens[nr_token].type = '+';
                        nr_token ++;
                        break;
          case '-':     tokens[nr_token].type = '-';
                        nr_token ++;
                        break;
          case '*':     if(nr_token == 0 || prec(tokens[nr_token-1].type) <= 5){
                            tokens[nr_token].type = TK_DEREF;
                        }
                        else{
                            tokens[nr_token].type = '*';
                        }
                        nr_token ++;
                        break;
          case '/':     tokens[nr_token].type = '/';
                        nr_token ++;
                        break;
          case TK_EQ:   tokens[nr_token].type = TK_EQ;
                        nr_token ++;
                        break;
          case '(':     tokens[nr_token].type = '(';
                        nr_token ++;
                        break;
          case ')':     tokens[nr_token].type = ')';
                        nr_token ++;
                        break;
          case TK_LT:   tokens[nr_token].type = TK_LT;
                        nr_token ++;
                        break;
          case TK_GT:   tokens[nr_token].type = TK_GT;
                        nr_token ++;
                        break;
          case TK_AND:  tokens[nr_token].type = TK_AND;
                        nr_token ++;
                        break;
          case TK_DEREF:tokens[nr_token].type = TK_DEREF;
                         nr_token ++;
                         break;
          case '$':     tokens[nr_token].type = '$';
                        strncpy(tokens[nr_token].str, substr_start, substr_len%32);
                        tokens[nr_token].str[substr_len%32] = '\0';
                        nr_token ++;
                        break;
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

bool check_parentheses(int p, int q){
    if(tokens[p].type != '(' || tokens[q].type != ')'){
        return false;
    }
    int cnt = 0;
    for(int i = p; i < q; i ++){
        if(tokens[i].type == '(')   cnt ++;
        if(tokens[i].type == ')')   cnt --;
        if(cnt == 0) return false;
    }
    if(tokens[q].type != ')'){
        panic("Parentheses not match\n");
    }
    if(cnt == 1) return true;
    else panic("Parentheses not match\n");
}

int find_op_position(int p, int q){
    int cnt = 0;
    int position = 0;
    int op = -1;
    for(int i = p; i <= q; i ++){
        if(cnt == 0){
            if(prec(tokens[i].type) <= prec(op)){
                op = tokens[i].type;
                position = i;
            }
        }
        if(tokens[i].type == '(') cnt ++;
        if(tokens[i].type == ')') cnt --;
    }
    return position;
}

uint32_t eval(int p, int q) {
  if (p > q) {
    /* Bad expression */
    panic("Bad expression: %d > %d\n", p, q);
    //return 0;
  }
  else if (p == q) {
    /* Single token.
     * For now this token should be a number.
     * Return the value of the number.
     */
    if(tokens[p].type == TK_DEC || tokens[p].type == TK_HEX){
        return (uint32_t)strtol(tokens[p].str, NULL, 0);
    }
    if(tokens[p].type == '$'){
        if(strcmp(tokens[p].str+1, "pc") == 0) return cpu.pc;
        else{
            for(int i = 0; i < 32; i ++){
                if(strcmp(tokens[p].str+1, regs[i]) == 0) return cpu.gpr[i]; 
            }
        }
    }
  }
  else if (check_parentheses(p, q) == true) {
    /* The expression is surrounded by a matched pair of parentheses.
     * If that is the case, just throw away the parentheses.
     */
    return eval(p + 1, q - 1);//remove parentheses
  }
  else {
    //op = the position of 主运算符 in the token expression;
    int op = find_op_position(p, q);
    int op_type = tokens[op].type;
    uint32_t val1;
    if(op_type != TK_DEREF){
        val1 = eval(p, op - 1);
    }
    uint32_t val2 = eval(op + 1, q);
    switch (op_type) {
      case '+': return val1 + val2;
      case '-': return val1 - val2;
      case '*': return val1 * val2;
      case '/': if(val2 !=0 ){
                    return val1 / val2;
                }
                else{
                    return val1;
                }
      case TK_EQ:   return val1 == val2;
      case TK_LT:   return val1 <= val2;
      case TK_AND:     return val1 && val2;
      case TK_DEREF:    return vaddr_read(val2, 4);
      default: assert(0);
    }
  }
  return 0;
}

uint32_t expr(char *e, bool *success) {
    if (!make_token(e)) {
    *success = false;
    return 0;
  }
  /* TODO: Insert codes to evaluate the expression. */
  //TODO();
  return eval(0, nr_token - 1);

  //return 0;
}
