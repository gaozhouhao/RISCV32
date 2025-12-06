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

#include <common.h>
#include <../src/monitor/sdb/sdb.h>
void init_monitor(int, char *[]);
void am_init_monitor();
void engine_start();
int is_exit_status_bad();

void test_expr() {
  FILE *fp = fopen("./tools/gen-expr/input", "r");
  if (fp == NULL) {
    printf("Cannot open input file!\n");
    return;
  }
  printf("Open file successful!\n");

  char line[65536];
  uint32_t expected = 0;
  char expr_buf[65536];
  int lineno = 0;
  while (fgets(line, sizeof(line), fp) != NULL) {
    lineno++;
    //printf("line %d: %s", lineno, line);
    if (sscanf(line, "%u %s", &expected, expr_buf) != 2) {
      printf("sscanf FAILED on line %d\n", lineno);
      continue;
    }

    bool success = true;
    word_t result = expr(expr_buf, &success);
    //printf("result:%d\texpected:%d\n", result, expected);
    assert(expected == result);
  }
  printf("test pass!\n");

  fclose(fp);
}


int main(int argc, char *argv[]) {
  /* Initialize the monitor. */
#ifdef CONFIG_TARGET_AM
  am_init_monitor();
#else
  init_monitor(argc, argv);
#endif

  //test_expr();
  /* Start engine. */
  engine_start();
  return is_exit_status_bad();
}
