/***************************************************************************************
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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%uu\", result); "
"  return 0; "
"}";
uint32_t position = 0;
int cnt = 0;

uint32_t cnt_num(uint32_t num){
    int cnt = 0;
    while(num){
        cnt ++;
        num /= 10;
    }
    return cnt;
}

uint32_t gen_num(){
    uint32_t num = rand()%1000000;
    int cnt = cnt_num(num);
    int tmp = 0;
    for(int i = cnt-1; i >= 0; i --){
        tmp = num;
        for(int j = 0; j < i; j ++){
            tmp /= 10;
        }
        tmp = tmp % 10;
        buf[position ++] = tmp + '0';
    }
    buf[position] = 'u';
    position ++;
    return num;
}

char gen_rand_op(){
    int op = rand() % 4;
    switch(op){
        case 0: buf[position] = '+'; break;
        case 1: buf[position] = '-'; break;
        case 2: buf[position] = '*'; break;
        case 3: buf[position] = '/'; break;
    }
    position ++;
    switch(op){
        case 0: return '+';
        case 1: return '-';
        case 2: return '*';
        case 3: return '/';
    }
    return 0;
}

void gen(char ch){
    buf[position] = ch;
    position ++;
}

int choose(int num){
    return  rand()%num;
}


uint32_t gen_rand_expr() {
    cnt ++;
    if(cnt < 100){
        switch (choose(3)) {
            case 0:
                uint32_t ret1 = gen_num();
                return ret1;
            case 1:
                //gen('(');
                uint32_t ret2 = gen_rand_expr();
                //gen(')');
                return ret2;    
            default:
                gen('(');
                uint32_t ret3 = gen_rand_expr();
                gen(')');
                char op = gen_rand_op();
                uint32_t start_pos = position;
                gen('(');
                uint32_t ret4 = gen_rand_expr();
                gen(')');
                switch(op){
                    case '+':return ret3 + ret4;
                    case '-':return ret3 - ret4;
                    case '*':return ret3 * ret4;
                    case '/':if(ret4 == 0){
                                position = start_pos;
                                buf[position++] = '1';
                                buf[position] = '\0';
                                return ret3;
                            }
                            else return ret3 / ret4;
                     }
        }
    }
    else
        return gen_num();
    return 0;
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    position = 0;
    cnt = 0;
    gen_rand_expr();
    buf[position] = '\0';
    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}
