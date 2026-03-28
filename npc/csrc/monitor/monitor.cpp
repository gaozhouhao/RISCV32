#include <getopt.h>
#include <npc_common.h>
#include <npc_memory.h>
#include <npc_include.h>
void init_difftest(char *ref_so_file, long img_size, int port);

void sdb_set_batch_mode();

static char *diff_so_file = NULL;
static char *img_file = NULL;
static int difftest_port = 1234;

void init_sdb();

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    //{"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"help"     , no_argument      , NULL, 'h'},
    //{"ftrace"   , required_argument, NULL, 'f'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:f:", table, NULL)) != -1) {
  printf("parse_args:\033[32m%c\033[0m\n", o);
    switch (o) {
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
      //case 'l': log_file = optarg; break;
      case 'd': diff_so_file = optarg; break;
      //case 'f': ftrace_elf_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\t-f,--ftrace=ELF_FILE    trace Function\n");
        printf("\n");
        exit(0);
    }
  }
  return 0;
}


static long load_img() {
    printf("img:\033[32m%s\033[0m\n", img_file);
  if (img_file == NULL) {
    printf("No image is given. Use the default build-in image.\n");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'\n", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  printf("The image is %s, size = %ld\n", img_file, size);
    assert(memory != NULL);
    assert(size <= 1<<22);
    fseek(fp, 0, SEEK_SET);
  int ret = fread(memory, size, 1, fp);
  assert(ret == 1);
  fclose(fp);
  printf("inst 1: %08x\n", memory[0]);
  return size;
}

void init_monitor(int argc, char *argv[]){
    parse_args(argc, argv);
    long img_size = load_img();
    //long img_size = 4096;
#if CONFIG_DIFFTEST
    printf("diff_so_file:\033[32m%s\033[0m\n", diff_so_file);
    init_difftest(diff_so_file, img_size, difftest_port);
#endif    
    
    init_sdb();
}




