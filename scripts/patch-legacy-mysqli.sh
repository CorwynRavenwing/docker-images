#!/bin/sh

set -e

echo "Checking legacy MySQL compatibility patches for PHP $PHP_VERSION..."

# 1. Patch mysqli.c for missing replication constants (if not already present)
if ! grep -q "#define MYSQL_RPL_MASTER" ext/mysqli/mysqli.c; then
    echo "-> Patching mysqli.c for replication constants..."
    sed -i '/#include "php.h"/a \
\
#ifndef MYSQL_RPL_MASTER\n\
#define MYSQL_RPL_MASTER 0\n\
#define MYSQL_RPL_SLAVE 1\n\
#define MYSQL_RPL_ADMIN 2\n\
#endif\n' ext/mysqli/mysqli.c
fi

# 2. Patch mysqli_api.c for missing gptr type (if not already present)
if ! grep -q "typedef char\* gptr;" ext/mysqli/mysqli_api.c; then
    echo "-> Patching mysqli_api.c for gptr type..."
    sed -i '/#include "php.h"/a \
\
#ifndef gptr\n\
typedef char* gptr;\n\
#endif\n' ext/mysqli/mysqli_api.c
fi

# 3. Patch mysqli_repl.c for missing replication functions (insert after headers)
if ! grep -q "STUBS FOR DEPRECATED REPLICATION FUNCTIONS" ext/mysqli/mysqli_repl.c; then
    echo "-> Patching mysqli_repl.c with replication stubs..."
    sed -i '/#include "php_mysqli.h"/a \
\
#ifndef MYSQL_RPL_MASTER\n\
#define MYSQL_RPL_MASTER 0\n\
#define MYSQL_RPL_SLAVE 1\n\
#define MYSQL_RPL_ADMIN 2\n\
#endif\n\
\
/* --- STUBS FOR DEPRECATED REPLICATION FUNCTIONS --- */\n\
static inline int mysql_disable_reads_from_master(MYSQL *mysql) { return 1; }\n\
static inline int mysql_disable_rpl_parse(MYSQL *mysql) { return 1; }\n\
static inline int mysql_enable_reads_from_master(MYSQL *mysql) { return 1; }\n\
static inline int mysql_enable_rpl_parse(MYSQL *mysql) { return 1; }\n\
static inline int mysql_master_query(MYSQL *mysql, const char *q, unsigned long length) { return 1; }\n\
static inline int mysql_rpl_parse_enabled(MYSQL *mysql) { return 0; }\n\
static inline int mysql_rpl_probe(MYSQL *mysql) { return 1; }\n\
static inline int mysql_rpl_query_type(const char *q, int len) { return 0; }\n\
static inline int mysql_slave_query(MYSQL *mysql, const char *q, unsigned long length) { return 1; }\n' ext/mysqli/mysqli_repl.c
fi

# end of patch