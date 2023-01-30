/*
 * Example spank plugin.
 *
 * This example spank plugin attempts to test as many SPANK features in one
 * plugin. It implements every possible SPANK function and also creates two
 * options ("example1asdf" and "example2") for salloc, sbatch, and srun.
 * Most of this plugin just prints text to files specific to each plugin or
 * to the job output file if using the job options. One function does something
 * a little more: slurm_spak_init_post_opt() copies the user environment so
 * it's available to the job prolog and epilog scripts.
 *
 * Compile with:
gcc -Wall -Werror -g -shared spank.c -o spank.so -fPIC \
	-I#INSTALL_PATH/include \
	-Wl,-rpath=#INSTALL_PATH/lib \
	-L#INSTALL_PATH/lib -lslurm
 *
 * Of course, change this path to wherever Slurm is installed.
 * #INSTALL_PATH
 *
 * -g is for debug info
 * -shared indicates shared library
 * -fPIC is because of extern char **environ - it must be position independent
 *  code
 * the rest of the flags are for linking
 *
 * You will need a plugstack.conf in the same directory as slurm.conf. It can
 * be as simple as this:
required spank.so
 *
 * Slurm spank documentation can be found at
 *   https://slurm.schedmd.com/spank.html
 */
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <slurm/spank.h>

/* All SPANK plugins must define this macro for the Slurm plugin loader. */
SPANK_PLUGIN("myspank", 42);

/* Required for the library function strstr() */
#define _GNU_SOURCE

/* TODO: Change this to a directory that exists in you file system. */
#define MY_DIR "#INSTALL_PATH/c#CLUSTER/log/spank"

/* Provide function prototypes for the spank_option table */
static int _example_cb(int val, const char *optarg, int remote);
static int _example2_cb(int val, const char *optarg, int remote);

extern char **environ;

/* The following is from slurm/spank.h */
#if 0
struct spank_option {
    char *         name;    /* long option provided by plugin               */
    char *         arginfo; /* one word description of argument if required */
    char *         usage;   /* Usage text                                   */
    int            has_arg; /* Does option require argument?                */
    int            val;     /* value to return using callback               */
    spank_opt_cb_f cb;      /* Callback function to check option value      */
};
#endif

struct spank_option spank_opts[] =
{
	{
		"example1asdf", "val", "Usage of example - spank option",
		1, 0, (spank_opt_cb_f) _example_cb /* must be spank_opt_cb_f */
	},
	{
		"example2", "val2", "Usage of example2 - spank option",
		1, 0, (spank_opt_cb_f) _example2_cb
	},
	SPANK_OPTIONS_TABLE_END /* Required as the last element in the
			     spank options table, defined in slurm/spank.h */
};

static void _handle_spank_err(spank_err_t rc, FILE *fp, int i)
{
	switch (rc) {
	case ESPANK_ERROR:
		fprintf(fp, "%s: option %s not used\n",
			__func__, spank_opts[i].name);
		break;
	case ESPANK_BAD_ARG:
		fprintf(fp, "%s: bad argument\n", __func__);
		break;
	case ESPANK_NOT_AVAIL:
		fprintf(fp, "%s: called from bad context, spank_opts %s not available\n",
			__func__, spank_opts[i].name);
		break;
	default:
		fprintf(fp, "%s: Invalid return code %d\n",
			__func__, rc);
		break;
	}
}

static int _get_opts(spank_t spank, const char *func)
{
	int num_elems;
	FILE *fp = NULL;
	char file_str[255];
	memset(file_str, 0, sizeof(file_str));
	snprintf(file_str, 254, "%s/get_opts_%s.txt", MY_DIR, func);
	fp = fopen(file_str, "a");
	if (!fp)
		return errno;

	fprintf(fp, "\n%s\n", __func__);

	num_elems = sizeof(spank_opts) / sizeof(spank_opts[0]);
	/* num_elems - 1 to exclude SPANK_OPTIONS_TABLE_END */
	for (int i = 0; i < num_elems - 1; i++) {
		char *optarg = NULL;
		spank_err_t rc =
			spank_option_getopt(spank, &spank_opts[i], &optarg);
		if (rc == ESPANK_SUCCESS) {
			/*
			 * ESPANK_SUCCESS is not in the enum spank_err_t so
			 * it doesn't work in the switch-case
			 */
			fprintf(fp, "%s: option:\n\tname: %s\n\targinfo:%s\n\tusage:%s\n\trequires argument:%s\n\treturn value:%d\n\targument:%s\n\n",
				__func__, spank_opts[i].name,
				spank_opts[i].arginfo,
				spank_opts[i].usage,
				spank_opts[i].has_arg ? "YES" : "NO",
				spank_opts[i].val, optarg);
		} else {
			_handle_spank_err(rc, fp, i);
		}
	}

	fflush(fp);
	fclose(fp);
	return ESPANK_SUCCESS;
}

static void _cb(int val, const char *optarg, int remote, const char *func)
{
	time_t current_time;
	struct tm * time_info;
	char time_string[9] = { '\0' }; /* space for "HH:MM:SS\0" */
	FILE *fp = NULL;
	char file_str[255];
	memset(file_str, 0, sizeof(file_str));
	snprintf(file_str, 254, "%s/cb_%s.txt", MY_DIR, func);
	fp = fopen(file_str, "a");
	if (!fp)
		printf("%s: unable to create file %s, something bad happened!",
		       __func__, file_str);

	time(&current_time);
	time_info = localtime(&current_time);

	strftime(time_string, sizeof(time_string), "%H:%M:%S", time_info);

	printf("%s: XXX %s hi, we're in the callback! optarg = %s, remote = %d, val = %d.\n",
	       func, time_string, optarg, remote, val);
	if (fp) {
		fprintf(fp, "%s: XXX %s hi, we're in the callback! optarg = %s, remote = %d, val = %d.\n",
		       func, time_string, optarg, remote, val);
		fclose(fp);
	}
}

static int _example2_cb(int val, const char *optarg, int remote)
{
	_cb(val, optarg, remote, __func__);
	return val;
}

static int _example_cb(int val, const char *optarg, int remote)
{
	_cb(val, optarg, remote, __func__);
	return val;
}

/*******************************************************************************
 * Begin implementation of spank API functions. Any of the following functions
 * can be implemented:
extern spank_f slurm_spank_init;
extern spank_f slurm_spank_job_prolog;
extern spank_f slurm_spank_init_post_opt;
extern spank_f slurm_spank_local_user_init;
extern spank_f slurm_spank_user_init;
extern spank_f slurm_spank_task_init_privileged;
extern spank_f slurm_spank_task_init;
extern spank_f slurm_spank_task_post_fork;
extern spank_f slurm_spank_task_exit;
extern spank_f slurm_spank_job_epilog;
extern spank_f slurm_spank_slurmd_exit;
extern spank_f slurm_spank_exit;

spank_option_getopt() can be called from the following functions:
extern spank_f slurm_spank_job_prolog;           yes
extern spank_f slurm_spank_local_user_init;      yes
extern spank_f slurm_spank_user_init;            yes
extern spank_f slurm_spank_task_init_privileged; yes
extern spank_f slurm_spank_task_init;            yes
extern spank_f slurm_spank_task_exit;            yes
extern spank_f slurm_spank_job_epilog;           yes


This function used to exist, but it was improperly implemented and was never
actually called, so it was removed completely in 20.02.
extern spank_f slurm_spank_slurmd_init;
 *
 ******************************************************************************/

/*
 * Called just after plugins are loaded. In remote context, this is just after
 * job step is initialized. This function is called before any plugin option
 * processing. This function is not called in slurmd context.
 */
int slurm_spank_init(spank_t spank, int argc, char *argv[])
{
	/* Register options */
	printf("%s: register options\n", __func__);
	spank_option_register(spank, &spank_opts[0]);
	spank_option_register(spank, &spank_opts[1]);
	return 0;
}

/*
 * Called at the same time as the job prolog. If this function returns a
 * negative value and the SPANK plugin that contains it is required in the
 * plugstack.conf, the node that this is run on will be drained.
 */
int slurm_spank_job_prolog(spank_t spank, int argc, char *argv[])
{
	//return _get_opts(spank, __func__);
	_get_opts(spank, __func__);
	//sleep(20);
	return ESPANK_SUCCESS;
}

#define STR_MAX 1024

static void _split_env_name_val(char name[STR_MAX], char **val)
{
	if ((val == NULL)) {
		printf("%s: You done messed up A-A-Ron! val==NULL\n", __func__);
		return;
	}
	*val = strstr(name, "=");
	/*
	 * Value is the string after the '='. If there wasn't an '=', something
	 * went wrong.
	 */
	if (*val) {
		/*
		 * Null-terminate name at the '=' character.
		 * val should point to the character after the '=' character.
		 */
		**val = '\0';
		*val = *val + 1;
	} else {
		printf("%s: ERROR: '=' not in env string %s\n",
		       __func__, name);
	}
}

/*
 * Called at the same point as slurm_spank_init, but after all user options to
 * the plugin have been processed. The reason that the init and init_post_opt
 * callbacks are separated is so that plugins can process system-wide options
 * specified in plugstack.conf in the init callback, then process user options,
 * and finally take some action in slurm_spank_init_post_opt if necessary. In
 * the case of a heterogeneous job, slurm_spank_init is invoked once per job
 * component.
 */
int slurm_spank_init_post_opt(spank_t spank, int argc, char *argv[])
{
	/*
	 * Copy user environment to spank environment so it's available in the
	 * job prolog and epilog scripts. Normally only a handful of SLURM_*
	 * environment variables are available during the prolog and epilog
	 * scripts; this makes all the user's normal environment variables
	 * available.
	 */
	int i = 0;
	char name[STR_MAX], *val;
	while (environ[i]) {
		//printf("%s\n", environ[i]);
		snprintf(name, STR_MAX, "%s", environ[i]);
		_split_env_name_val(name, &val);
		//printf("\tname: \"%s\", value: \"%s\"\n\n", name, val);
		spank_job_control_setenv(spank, name, val, 1);
		i++;
	}
	return 0;
}

/*
 * Called in local (srun) context only after all options have been processed.
 * This is called after the job ID and step IDs are available. This happens in
 * srun after the allocation is made, but before tasks are launched.
 */
int slurm_spank_local_user_init (spank_t spank, int argc, char *argv[])
{
	return _get_opts(spank, __func__);
}

/*
 * Called in remote context after privileges are dropped.
 */
int slurm_spank_user_init(spank_t spank, int argc, char *argv[])
{
	return _get_opts(spank, __func__);
}

int slurm_spank_task_init_privileged(spank_t spank, int ac, char *argv[])
{
	return _get_opts(spank, __func__);
}

int slurm_spank_task_init(spank_t spank, int ac, char *argv[])
{
	return _get_opts(spank, __func__);
}

int slurm_spank_task_post_fork(spank_t spank, int ac, char *argv[])
{
	return 0;
}

int slurm_spank_task_exit(spank_t spank, int ac, char *argv[])
{
	return _get_opts(spank, __func__);
}

int slurm_spank_job_epilog(spank_t spank, int ac, char *argv[])
{
	return _get_opts(spank, __func__);
}

int slurm_spank_slurmd_exit(spank_t spank, int ac, char *argv[])
{
	printf("XXXXXXX%sXXXXXXXX\n",__func__);
	FILE *fp = NULL;
	char file_str[255];
	memset(file_str, 0, sizeof(file_str));
	snprintf(file_str, 254, "%s/%s.txt", MY_DIR, __func__);
	fp = fopen(file_str, "a");
	if (!fp)
		return errno;

	fprintf(fp, "\n%s\n", __func__);
	fflush(fp);
	fclose(fp);
	return 0;
}

int slurm_spank_exit(spank_t spank, int ac, char *argv[])
{
	int rc = 0;
	printf("%s start\n",__func__);
	FILE *fp = NULL;
	char file_str[255];
	memset(file_str, 0, sizeof(file_str));
	snprintf(file_str, 254, "%s/%s.txt", MY_DIR, __func__);
	fp = fopen(file_str, "a");
	if (!fp) {
		rc = errno;
		printf("ERROR trying to open %s: %m\n", file_str);
		return rc;
	}

	fprintf(fp, "%s:\nargc:%d\n",
		__func__, ac);
	if (ac) {
		fprintf(fp, "args:\n");
		for (int i = 0; i < ac; i++)
			fprintf(fp, "\t%s\n", argv[i]);
	}
	fprintf(fp, "Done\n\n");
	fflush(fp);
	fclose(fp);
	printf("%s end\n",__func__);
	return 0;
}
