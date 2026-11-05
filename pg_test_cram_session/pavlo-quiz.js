const pavloQuizData = {
    topics: {
        T1: "Installation, Configuration & Upgrades",
        T2: "Connecting, Database Objects & SQL",
        T3: "Roles & Privileges",
        T4: "Backup & Recovery",
        T5: "Server Architecture & Memory",
        T6: "MVCC, Transactions & Locks",
        T7: "VACUUM, ANALYZE & Autovacuum",
        T8: "Logging & Monitoring"
    },
    questions: [
        {
            id: 1, topic: 'T1',
            question: "You need PostgreSQL 16 and 18 installed on the same host. Which repository supports that?",
            options: ["PGDG carries every supported major version side by side; a distribution repository ships one.", "Only the single default PostgreSQL package in a distribution repository", "The Python Package Index, which installs PostgreSQL server clusters", "The extension catalog, which installs additional server major versions"],
            answer: 'A'
        },
        {
            id: 2, topic: 'T1',
            question: "After installing the packages on Rocky Linux, psql reports \"connection refused.\" What step is missing?",
            options: ["Grant CONNECT on the postgres database before starting the server", "The cluster was never initialized. Run the packaged initdb setup, then enable and start the service. Debian does this for you; Red Hat does not.", "Run ANALYZE to create the initial system catalogs", "Change every pg_hba.conf entry to trust; package installation always starts the cluster"],
            answer: 'B'
        },
        {
            id: 3, topic: 'T1',
            question: "You are on a host you did not build and need to find the configuration file actually in use. What do you run?",
            options: ["Read the first postgresql.conf found under /etc; all clusters share it", "Use psql --version to display all active server configuration paths", "Run SHOW config_file; use SHOW data_directory; and SHOW hba_file; for the other paths. Run pg_config --bindir for the binaries.", "Assume the configuration is in the working directory of the psql client"],
            answer: 'C'
        },
        {
            id: 4, topic: 'T1',
            question: "What is stored in global/ that is not in base/?",
            options: ["Only archived WAL segments awaiting recovery", "One directory of user-table files per database", "Only temporary files belonging to individual sessions", "The cluster-wide catalogs shared by every database, including roles and tablespaces. base/ holds one subdirectory of relation files per database."],
            answer: 'D'
        },
        {
            id: 5, topic: 'T1',
            question: "Name the two tablespaces that exist in every cluster.",
            options: ["pg_default, for ordinary objects, and pg_global, for the shared catalogs", "public for tables and pg_catalog for indexes", "template0 for shared catalogs and template1 for user data", "pg_wal for permanent tables and pg_temp for shared catalogs"],
            answer: 'A'
        },
        {
            id: 6, topic: 'T1',
            question: "You changed shared_buffers and reloaded, but SHOW still reports the old value. Why?",
            options: ["SHOW reads only the original installation defaults", "shared_buffers has postmaster context, so it requires a full restart. pg_settings.pending_restart lists parameters still waiting for a restart.", "Reload works only after running CHECKPOINT twice", "The new setting applies only after reconnecting psql, without restarting the server"],
            answer: 'B'
        },
        {
            id: 7, topic: 'T1',
            question: "A permissive trust line sits above your scram-sha-256 rule for the same address. Which one applies?",
            options: ["scram-sha-256, because the strongest matching method always wins", "Both rules must authenticate the client successfully", "The trust line applies. PostgreSQL stops at the first matching rule, so the stricter rule below is never evaluated.", "The last matching rule, because later entries override earlier entries"],
            answer: 'C'
        },
        {
            id: 8, topic: 'T1',
            question: "Which sslmode both encrypts the connection and proves you reached the intended server?",
            options: ["prefer", "require", "verify-ca", "verify-full requires encryption and validates the certificate and hostname. verify-ca validates the CA but not the hostname."],
            answer: 'D'
        },
        {
            id: 9, topic: 'T1',
            question: "Why might systemctl report the service as inactive while psql connects successfully?",
            options: ["The cluster was started directly with pg_ctl, so systemd does not manage it and will not restart it on boot.", "psql starts a complete PostgreSQL server automatically whenever it connects", "An inactive service means all PostgreSQL backends are paused, not stopped", "systemctl reports only whether autovacuum is enabled"],
            answer: 'A'
        },
        {
            id: 10, topic: 'T1',
            question: "pg_isready exits with 1. What does that tell you, and how does it differ from exit code 2?",
            options: ["1 means accepting connections; 2 means the password is incorrect", "Exit code 1 means the server responded but is rejecting connections, typically because it is still starting or in recovery. Exit code 2 means nothing responded.", "1 means no response; 2 means the server is accepting read-only connections", "Both mean the server accepted a connection, but the database does not exist"],
            answer: 'B'
        },
        {
            id: 11, topic: 'T1',
            question: "How long is a major version supported, and what happens when that support period ends?",
            options: ["One year, followed by indefinite security-only updates", "Three years, followed by automatic upgrades to the next major version", "Five years from release. After that, no further fixes are issued, including security fixes.", "Ten years, after which existing clusters refuse to start"],
            answer: 'C'
        },
        {
            id: 12, topic: 'T1',
            question: "Does a minor update require pg_upgrade or a dump and restore?",
            options: ["Always pg_upgrade, because every release changes the storage format", "Always dump/restore, because minor versions cannot share data files", "Neither, and the running server immediately uses new binaries without a restart", "Neither. Update the packages and restart. Read the release notes; some fixes occasionally require a manual follow-up, such as reindexing."],
            answer: 'D'
        },
        {
            id: 13, topic: 'T1',
            question: "Which method completes in minutes, almost regardless of database size, and why?",
            options: ["pg_upgrade, especially with --link or --clone, because it rewrites the catalogs and reuses the existing data files instead of copying rows.", "It skips every compatibility check and converts rows only when users read them", "It upgrades only the psql client and leaves the old server running", "It discards indexes and permanently avoids rebuilding system catalogs"],
            answer: 'A'
        },
        {
            id: 14, topic: 'T1',
            question: "Which method leaves you unable to fall back to the old cluster?",
            options: ["pg_upgrade in its default copy mode", "pg_upgrade with --link. The two clusters share files, so once the new one starts, the old one is no longer safe to use.", "A logical dump restored into a separate cluster", "pg_upgrade --clone, because every clone is a hard link"],
            answer: 'B'
        },
        {
            id: 15, topic: 'T2',
            question: "Where should a password be placed so it is not exposed?",
            options: ["Put the password directly in a shell command URI", "Export PGPASSWORD in every user's shell startup file", "Store it in a password file, ~/.pgpass, with mode 0600 (on Unix, a less restrictive mode causes the file to be ignored), or let psql prompt for it. The documentation advises against using PGPASSWORD because, on some systems, ps can show it to other users.", "Store ~/.pgpass with mode 0644 so libpq can read it"],
            answer: 'C'
        },
        {
            id: 16, topic: 'T2',
            question: "Which meta-command shows a table’s columns, indexes, and constraints?",
            options: ["\\dt tablename; it always includes every column and constraint", "\\h tablename; SQL help describes the live table", "\\? tablename; command help inspects the live table", "Use \\d tablename. Append + for more detail, such as column comments (\\dt+ adds sizes). \\? lists every meta-command; \\h gives SQL syntax help."],
            answer: 'D'
        },
        {
            id: 17, topic: 'T2',
            question: "You installed an extension into template1. What happens to databases created afterward?",
            options: ["Every database created afterward from template1, the default template, gets a copy of it. Use TEMPLATE template0 when you need a pristine database.", "They share the same extension catalog rows with template1 forever", "They never inherit extensions because CREATE DATABASE copies only schema names", "Every existing database also receives the extension immediately"],
            answer: 'A'
        },
        {
            id: 18, topic: 'T2',
            question: "With the default search_path of \"$user\", public, where does an unqualified CREATE TABLE place the table?",
            options: ["Always in public, even if a searchable schema named for the role exists", "In the schema named after your role, if that schema exists; otherwise, in public. The first schema in the path that exists is the target, and you still need CREATE privilege on it.", "In every schema listed in search_path", "In pg_catalog, because system schemas always receive unqualified objects"],
            answer: 'B'
        },
        {
            id: 19, topic: 'T2',
            question: "Which ALTER TABLE operations avoid rewriting the whole table?",
            options: ["Only adding a column whose default calls random()", "Every column type change, regardless of conversion requirements", "Adding a nullable column or one with a nonvolatile default avoids a rewrite in PostgreSQL 11 and later. Most column type changes rewrite the table and its indexes.", "Adding any column with a volatile default, but never a nullable column"],
            answer: 'C'
        },
        {
            id: 20, topic: 'T2',
            question: "Which type should hold a monetary amount, and which types should be avoided?",
            options: ["real, because its decimal arithmetic is exact", "double precision, because more bits guarantee exact decimal fractions", "text, because it enforces currency precision during arithmetic", "numeric is the type the documentation recommends for monetary amounts, for example, numeric(12,2). Avoid real and double precision; they are inexact, so some values are stored only as approximations."],
            answer: 'D'
        },
        {
            id: 21, topic: 'T2',
            question: "How does SELECT \"total\" differ from SELECT 'total'?",
            options: ["Double quotes delimit an identifier, so PostgreSQL looks for a column called total. Single quotes delimit a string literal.", "Both produce the same string literal", "Double quotes produce a string; single quotes identify a column", "Single quotes are valid only around numeric values"],
            answer: 'A'
        },
        {
            id: 22, topic: 'T2',
            question: "Name the six built-in index types, and say what a failed CREATE INDEX CONCURRENTLY leaves behind.",
            options: ["B-tree, hash, bitmap, clustered, columnstore and GIN; a valid empty index", "B-tree, hash, GiST, SP-GiST, GIN, and BRIN. A failed operation can leave an invalid index; drop it and retry, or rebuild it with REINDEX INDEX CONCURRENTLY.", "B-tree, heap, WAL, GiST, GIN and BRIN; a corrupted table that must be restored", "B-tree, hash, GiST, SP-GiST, GIN and BRIN; no index can remain after a failure"],
            answer: 'B'
        },
        {
            id: 23, topic: 'T2',
            question: "What does REFRESH MATERIALIZED VIEW CONCURRENTLY require?",
            options: ["Any index, including a partial or expression index, on an unpopulated view", "A primary key on every base table, with no index on the materialized view", "It requires at least one unique index on the materialized view that uses only column names, with no expression or WHERE clause. The view must already be populated. Without such an index, only a plain refresh works, and it can block readers.", "An ACCESS EXCLUSIVE lock held manually before starting the refresh"],
            answer: 'C'
        },
        {
            id: 24, topic: 'T2',
            question: "Why do sequence-generated IDs contain gaps?",
            options: ["PostgreSQL deliberately skips every tenth value to reserve space for VACUUM", "Every rollback decrements the sequence, causing duplicate IDs rather than gaps", "Sequences allocate values only at COMMIT, so gaps prove physical corruption", "nextval() is never rolled back, so concurrent transactions do not block it. A number taken by a transaction that aborts is not reused. With a cache above 1, numbers reserved but never used by a session are also lost when it ends."],
            answer: 'D'
        },
        {
            id: 25, topic: 'T2',
            question: "Which of the two can commit inside itself, and how is it invoked?",
            options: ["A procedure, invoked with CALL, can do so as long as the CALL is not inside a transaction block and the procedure is not SECURITY DEFINER. A function runs in the caller’s transaction, so it cannot start or end one.", "A function invoked with SELECT, because it always owns a separate transaction", "Any function or procedure, even inside an explicit BEGIN block", "Only a trigger function, because each trigger gets an autonomous transaction"],
            answer: 'A'
        },
        {
            id: 26, topic: 'T3',
            question: "How does CREATE USER differ from CREATE ROLE?",
            options: ["CREATE USER creates an operating-system account, while CREATE ROLE creates a database object", "Only their defaults differ: CREATE USER assumes LOGIN, while CREATE ROLE assumes NOLOGIN. Both create the same object: a role.", "CREATE USER always grants SUPERUSER, while CREATE ROLE never can", "Users can own tables, but roles cannot"],
            answer: 'B'
        },
        {
            id: 27, topic: 'T3',
            question: "Since version 16, what can a CREATEROLE role do to roles it did not create?",
            options: ["Only knowledge of the role's name; CREATEROLE overrides all membership checks", "CONNECT on any database owned by the target role", "Nothing unless it holds ADMIN OPTION on them. It gets ADMIN OPTION automatically only on roles it creates, and it cannot grant or revoke REPLICATION or BYPASSRLS.", "USAGE on public, which automatically grants role-administration rights"],
            answer: 'C'
        },
        {
            id: 28, topic: 'T3',
            question: "You revoke every privilege from a role, but it can still drop the table. Why?",
            options: ["DROP TABLE is automatically granted to PUBLIC on every table", "Revoking privileges takes effect only after a server restart", "SELECT privilege implicitly includes DROP even after revocation", "The role owns the table. The right to alter or drop an object comes with ownership, not a grant, so it cannot be revoked. Change the owner or reassign ownership of the objects, then drop the role."],
            answer: 'D'
        },
        {
            id: 29, topic: 'T3',
            question: "SELECT was granted on all tables, yet a table created today is inaccessible. What fixes it?",
            options: ["Grant privileges on the new table now (rerunning the grant on all tables works, too). For tables created later, use ALTER DEFAULT PRIVILEGES for the role that creates them. It does not affect tables that already exist.", "Run ALTER DEFAULT PRIVILEGES once; it retroactively changes every existing table", "Grant CONNECT again; it automatically grants SELECT on future tables", "Restart PostgreSQL so the original ALL TABLES grant discovers new objects"],
            answer: 'A'
        },
        {
            id: 30, topic: 'T3',
            question: "What changed about the public schema in PostgreSQL 15?",
            options: ["PUBLIC lost both USAGE and CONNECT, so no role can access public", "CREATE is no longer granted to PUBLIC by default, so only the database owner can create objects there; everyone still has USAGE. Databases upgraded from version 14 or earlier keep the old grant.", "Every login role automatically owns public and may drop it", "The public schema was removed and replaced by a schema named after each role"],
            answer: 'B'
        },
        {
            id: 31, topic: 'T4',
            question: "Which backup type can restore a single table into a newer major version?",
            options: ["A physical base backup copied directly into the newer server's data directory", "Archived WAL alone, with no base backup", "A logical backup. A physical backup restores the whole cluster onto the same major version and is the only route to point-in-time recovery.", "A copy of pg_control, because it contains the table definitions and rows"],
            answer: 'C'
        },
        {
            id: 32, topic: 'T4',
            question: "What does pg_dump not include, and what do you run to capture it?",
            options: ["Table rows and indexes; capture them with pg_isready", "Schemas and views; capture them with a configuration reload", "All extension objects; copy the server executable to preserve them", "Roles and tablespaces, because they are cluster-wide rather than part of any one database. Run pg_dumpall --globals-only alongside it."],
            answer: 'D'
        },
        {
            id: 33, topic: 'T4',
            question: "You hold a custom-format dump. Which tool restores it, and what does ON_ERROR_STOP change for a psql restore?",
            options: ["pg_restore restores custom-format dumps; psql replays only plain SQL dumps. ON_ERROR_STOP makes psql stop at the first error and exit with status 3, but the restore is still partial. For an all-or-nothing restore, add -1 (--single-transaction).", "Use psql for custom format; ON_ERROR_STOP silently skips failing commands", "Use pg_restore only for plain SQL; ON_ERROR_STOP rolls back all earlier commits automatically", "Use initdb for custom format; ON_ERROR_STOP repairs damaged archive entries"],
            answer: 'A'
        },
        {
            id: 34, topic: 'T4',
            question: "Why does -X stream matter?",
            options: ["It streams only table rows, so neither mode needs WAL for recovery", "A second connection streams the WAL written during the copy, so the backup can be used on its own. With -X none, the backup needs WAL from an archive.", "It disables all checkpoints and guarantees zero impact on the primary", "It writes only WAL with no data files, while -X none produces a standalone backup"],
            answer: 'B'
        },
        {
            id: 35, topic: 'T4',
            question: "What must archive_command return, and what happens if it reports success incorrectly?",
            options: ["Return zero before copying so PostgreSQL can recycle the segment immediately", "Return nonzero on success; zero tells PostgreSQL to retry", "It must return zero only when the segment is safely stored. A false success breaks the archive chain because PostgreSQL then removes or recycles the segment. A nonzero code makes PostgreSQL retry while pg_wal keeps growing.", "Return the segment size as the exit status; PostgreSQL ignores other values"],
            answer: 'C'
        },
        {
            id: 36, topic: 'T4',
            question: "What two things must already exist before PITR is possible?",
            options: ["Only a recent pg_dump and the current postgresql.conf", "Only the final WAL segment containing the target timestamp", "A logical schema dump and the server logs since installation", "A base backup and an unbroken chain of archived WAL from the start of that backup to the target moment."],
            answer: 'D'
        },
        {
            id: 37, topic: 'T5',
            question: "Does the postmaster execute your queries?",
            options: ["No. It listens on the port, starts one backend process per connection, and supervises the background processes. Each query runs in the client’s own backend.", "Yes; all clients share one SQL-execution process", "Only SELECT queries; UPDATE queries run in the WAL writer", "Only when a client connection is idle"],
            answer: 'A'
        },
        {
            id: 38, topic: 'T5',
            question: "Is the checkpointer governed by max_worker_processes?",
            options: ["Yes; it cannot start if parallel workers use every slot", "No. That setting limits background workers: parallel workers, logical replication workers, and those registered by extensions. Auxiliary processes such as the checkpointer start regardless.", "Yes; max_worker_processes is the total limit for every PostgreSQL operating-system process", "No; the checkpointer is a thread inside every client backend"],
            answer: 'B'
        },
        {
            id: 39, topic: 'T5',
            question: "Why is an idle connection not free?",
            options: ["Idle connections continuously rewrite every table they have accessed", "An idle connection always reserves work_mem times max_connections immediately", "Each connection is its own operating-system backend process with private memory, and it holds a connection slot even when idle. The answer to serving many clients is a connection pooler, not a much larger max_connections.", "Idle connections hold ACCESS EXCLUSIVE locks on all databases"],
            answer: 'C'
        },
        {
            id: 40, topic: 'T5',
            question: "What does it mean for a page in shared buffers to be dirty?",
            options: ["Its checksum failed and it must be discarded immediately", "It contains rows that every active transaction has deleted", "It has been archived and can no longer be modified", "It has been changed in memory but not yet written to disk. That is safe because the WAL record describing the change reaches the disk first."],
            answer: 'D'
        },
        {
            id: 41, topic: 'T5',
            question: "Is work_mem a per-connection limit?",
            options: ["No. It applies per sort or hash operation, and hash operations may use work_mem * hash_mem_multiplier. One query may use it several times, and every concurrent query and parallel worker does the same.", "Yes; it caps all memory used by one backend, including shared buffers", "Yes; every connection allocates exactly work_mem when it starts", "No; it is a cluster-wide pool shared equally by every running query"],
            answer: 'A'
        },
        {
            id: 42, topic: 'T5',
            question: "Which of the three writers signals a tuning problem?",
            options: ["The background writer doing its normal work ahead of clients", "A client backend writing dirty buffers itself. Many such writes suggest shared_buffers or checkpoint settings need tuning, and the queries pay for those writes.", "The checkpointer writing buffers during a scheduled checkpoint", "The archiver copying completed WAL segments to archive storage"],
            answer: 'B'
        },
        {
            id: 43, topic: 'T5',
            question: "Which reaches durable storage first, the data page or the WAL record?",
            options: ["The changed data page, so recovery can infer the missing WAL", "Either one; the ordering never matters when fsync is enabled", "The WAL record. That ordering makes crash recovery possible and is what the name write-ahead refers to.", "The server log message describing the SQL statement"],
            answer: 'C'
        },
        {
            id: 44, topic: 'T5',
            question: "What does synchronous_commit = off put at risk?",
            options: ["All historical commits, because it disables WAL completely", "Structural database consistency after every clean shutdown", "Only uncommitted transactions; acknowledged commits remain fully durable", "The most recent commits, which a crash can lose (at most about three times wal_writer_delay). It does not risk database inconsistency."],
            answer: 'D'
        },
        {
            id: 45, topic: 'T6',
            question: "Why does a long-running report not block concurrent updates?",
            options: ["An update adds a new row version instead of changing the old one in place, and each statement reads through a snapshot. Reading a row and writing it do not conflict.", "The report takes an ACCESS EXCLUSIVE lock and postpones updates until it finishes", "Every SELECT copies the entire database to a temporary cluster first", "Updates overwrite visible rows in place, and the report accepts partially written values"],
            answer: 'A'
        },
        {
            id: 46, topic: 'T6',
            question: "You deleted a million rows, but the file did not shrink. Why?",
            options: ["DELETE never changes visibility and requires a restart to remove rows", "DELETE only marks row versions as deleted. Standard VACUUM later makes that space reusable inside the table; it does not return it to the operating system, except for empty pages at the end of the table.", "The operating system returns deleted-row space only after a checkpoint", "Every DELETE creates a second permanent copy of the table"],
            answer: 'B'
        },
        {
            id: 47, topic: 'T6',
            question: "What is the default isolation level, and what can change under it mid-transaction?",
            options: ["Serializable; each statement sees all uncommitted changes from other sessions", "Repeatable read; every statement takes a fresh snapshot of committed data", "READ COMMITTED. Each statement takes a fresh snapshot, so changes committed by others between your statements become visible.", "Read uncommitted; dirty reads are enabled by default"],
            answer: 'C'
        },
        {
            id: 48, topic: 'T6',
            question: "Which lock mode conflicts with a plain SELECT?",
            options: ["ROW EXCLUSIVE, so every INSERT blocks plain SELECT", "SHARE UPDATE EXCLUSIVE, so every standard VACUUM blocks readers", "ACCESS SHARE, so two plain SELECT statements cannot overlap", "ACCESS EXCLUSIVE, taken by DROP TABLE, TRUNCATE, and many forms of ALTER TABLE. It is the only table-level mode that conflicts with ACCESS SHARE."],
            answer: 'D'
        },
        {
            id: 49, topic: 'T6',
            question: "Which column in pg_locks identifies a waiting session, and what function names its blocker?",
            options: ["granted = false identifies a waiting session. pg_blocking_pids(pid) returns the blocking process IDs directly.", "Look for pg_locks.granted = true and call pg_backend_pid() to list blockers", "Look for pg_stat_activity.state = idle and call pg_blocking_pids(pid)", "Look for pg_locks.mode = unlocked and call pg_cancel_backend(pid) to list blockers"],
            answer: 'A'
        },
        {
            id: 50, topic: 'T6',
            question: "How does PostgreSQL detect a deadlock?",
            options: ["It aborts every lock waiter immediately, without checking for a cycle", "A session that has waited longer than deadlock_timeout runs the check. If a cycle exists, one transaction is aborted; otherwise, it keeps waiting.", "The checkpointer checks locks only at each checkpoint and restarts the server if needed", "It waits for statement_timeout and always aborts every transaction involved"],
            answer: 'B'
        },
        {
            id: 51, topic: 'T7',
            question: "Why does PostgreSQL need VACUUM, and which kind returns space to the operating system?",
            options: ["VACUUM only rebuilds indexes, and ANALYZE removes dead rows", "Plain VACUUM always compacts every table into a smaller new file", "VACUUM serves four purposes: reusing the space occupied by dead row versions, updating planner statistics (the ANALYZE step), maintaining the visibility map, and preventing transaction ID wraparound. Only VACUUM FULL, which rewrites the table, returns space to the operating system.", "ANALYZE freezes all transaction IDs, so VACUUM is unnecessary when statistics are fresh"],
            answer: 'C'
        },
        {
            id: 52, topic: 'T7',
            question: "What does PostgreSQL do if freezing falls critically far behind?",
            options: ["PostgreSQL silently resets transaction IDs to zero with no vacuum needed", "Disabling autovacuum also disables all wraparound safeguards", "The server deletes the oldest tables automatically to free transaction IDs", "It launches an anti-wraparound autovacuum even if autovacuum is disabled, issues warnings, and, at the limit, refuses to assign new transaction IDs. Only read-only transactions can start."],
            answer: 'D'
        },
        {
            id: 53, topic: 'T7',
            question: "Which VACUUM variant returns disk space to the operating system, and at what cost?",
            options: ["VACUUM FULL rewrites the table into a new file under an ACCESS EXCLUSIVE lock, which blocks all reads and writes. It also needs room for the new copy until it completes.", "VACUUM ANALYZE rewrites every table without blocking or needing extra disk space", "VACUUM FREEZE always shrinks every data file while allowing all DDL", "Standard VACUUM always compacts the whole table under only an ACCESS SHARE lock"],
            answer: 'A'
        },
        {
            id: 54, topic: 'T7',
            question: "What triggers autovacuum on a table?",
            options: ["Any single DELETE immediately forces a full-table rewrite", "Autovacuum is triggered when the number of dead rows since the last vacuum passes a base threshold plus a scale factor multiplied by the table’s row count, so a large table needs far more dead rows to trigger it. Inserted rows have a similar trigger.", "The database reaches a fixed age of exactly 24 hours regardless of activity", "Every SELECT increments a dead-tuple counter until it reaches max_connections"],
            answer: 'B'
        },
        {
            id: 55, topic: 'T7',
            question: "Which two parameters set the vacuum trigger, and what are their defaults?",
            options: ["vacuum_cost_limit = 50 and vacuum_cost_delay = 0.2; these also trigger ANALYZE", "autovacuum_naptime = 50 and autovacuum_max_workers = 0.2", "autovacuum_vacuum_threshold defaults to 50, and autovacuum_vacuum_scale_factor defaults to 0.2. Autoanalyze has an equivalent pair, with defaults of 50 and 0.1.", "autovacuum_vacuum_threshold = 5000 and autovacuum_vacuum_scale_factor = 1.0; ANALYZE has no separate settings"],
            answer: 'C'
        },
        {
            id: 56, topic: 'T7',
            question: "Which columns show that autovacuum is falling behind on a table?",
            options: ["A low seq_scan count and a recent last_analyze timestamp alone", "A large n_live_tup with zero dead tuples and a recent last_autovacuum", "A high idx_scan count and a small number of columns", "A rising n_dead_tup relative to n_live_tup, together with an old last_autovacuum timestamp."],
            answer: 'D'
        },
        {
            id: 57, topic: 'T8',
            question: "Which destinations produce structured output that a log shipper or table load can consume directly?",
            options: ["jsonlog produces one JSON object per line, and csvlog produces fixed columns for COPY. Both require logging_collector = on. log_destination accepts a comma-separated list, so you can write to more than one destination.", "stderr and syslog, which both emit fixed-column records that COPY can load directly", "csvlog alone, because jsonlog is plain text and cannot be consumed by log shippers", "eventlog and journald, which PostgreSQL writes regardless of log_destination"],
            answer: 'A'
        },
        {
            id: 58, topic: 'T8',
            question: "Which setting captures slow statements with their text, and in what unit is it set?",
            options: ["log_duration in seconds, with -1 disabling statement logging", "log_min_duration_statement is set in milliseconds. -1 disables it, and 0 logs every statement. It is a duration threshold, not a severity level.", "log_min_messages in milliseconds, with 0 logging every statement", "log_statement in seconds, with -1 disabling statements over the threshold"],
            answer: 'B'
        },
        {
            id: 59, topic: 'T8',
            question: "How can a rotation setting silently destroy last week’s logs?",
            options: ["Set log_rotation_age to 0 so PostgreSQL removes all previous log files at startup", "Set log_rotation_size to 0 to truncate every existing log file when the server starts", "When log_truncate_on_rotation is on and log_filename uses a repeating pattern, such as the day of the week, time-based rotation overwrites the same file on the next cycle.", "Set logging_collector to on, which replaces the previous log at every rotation"],
            answer: 'C'
        },
        {
            id: 60, topic: 'T8',
            question: "Which setting records every INSERT, UPDATE, and DELETE, but not SELECT?",
            options: ["log_statement = 'ddl', which records data changes but excludes schema changes", "log_statement = 'all', which records INSERT, UPDATE and DELETE but filters out SELECT", "log_min_duration_statement = 0, which records modifications but excludes reads", "log_statement = 'mod'. It also logs everything that 'ddl' logs; 'all' adds SELECT and every other statement."],
            answer: 'D'
        },
        {
            id: 61, topic: 'T8',
            question: "Why is log_duration on its own rarely enough?",
            options: ["It records the duration without the statement text, so there is nothing to attribute the time to. log_min_duration_statement logs the text with the duration.", "It records statement text but never the duration, so the slow operation cannot be identified", "It applies only to statements that exceed log_min_duration_statement", "It logs only connection setup and disconnection durations"],
            answer: 'A'
        },
        {
            id: 62, topic: 'T8',
            question: "Which parameter records every temporary file, and what value logs them all?",
            options: ["log_statement, set to 0 to record temporary files but not SQL text", "log_temp_files: 0 logs every temporary file; -1 disables logging.", "log_rotation_size: 0 logs each temporary file as a separate server log", "log_duration: -1 logs every temporary file and its size"],
            answer: 'B'
        },
        {
            id: 63, topic: 'T8',
            question: "What does the %q escape do?",
            options: ["It prints the current query ID in each log line", "It adds an empty user and database field to background-process log lines", "It produces no output, but tells non-session processes to stop at that point, so background-process log lines do not contain empty user and database fields. Session processes ignore it.", "It suppresses all log output from session processes"],
            answer: 'C'
        },
        {
            id: 64, topic: 'T8',
            question: "Why set lc_messages to C and log_timezone to UTC?",
            options: ["C sets the log timestamps to English, while UTC translates error messages into a common timezone", "UTC gives original English messages and C prevents daylight saving time changes in timestamps", "Both settings force PostgreSQL to write logs in the server process locale and local timezone", "C provides the original English message text that the documentation and many tools assume. UTC keeps log timestamps comparable across servers and avoids repeated timestamps during daylight saving time changes."],
            answer: 'D'
        }
    ]
};
