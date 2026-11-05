# OAPE PostgreSQL DBA-1 — Practice Exam 04

80 multiple-choice questions. Topic distribution is a weighted estimate (not officially published), based on the relative number of learning objectives OAPE lists per topic on https://www.oapg-edu.org/certifications/ — topics with more sub-objectives get proportionally more questions:

- T1 Installation, Versioning & Basic Configuration: 15
- T2 Connecting to PostgreSQL, Database Objects & Basic SQL: 12
- T3 Roles & Privileges: 5
- T4 Backup & Recovery: 7
- T5 Server Architecture & Background Processes: 9
- T6 MVCC & Transaction Management: 7
- T7 VACUUM, ANALYZE & Autovacuum: 7
- T8 Monitoring & Logging: 18

Questions are scattered (not grouped by topic). Scoped to PostgreSQL 18 only. A handful of questions revisit concepts you missed on prior exams (flagged as genuine gaps, not just PG18 trivia) — everything else is new.

**How to take it:** Answer inline by putting your letter choice after each question (e.g. `Answer: B`). Do not look anything up — treat it like the real exam. When done, tell Claude and it will grade it and log your results by topic.

---

**1.** In pg_stat_activity, what does a `state` of `idle in transaction` indicate?
A. The connection is closed
B. The session has an open transaction but is not currently executing a statement — potentially holding locks/old snapshots open
C. The query is actively scanning a table
D. The backend has crashed

Answer: 

**2.** What is the key advantage of using the PGDG (PostgreSQL Global Development Group) repository over your Linux distribution's default package repository?
A. It provides GUI tools for administration
B. It is the only repository that supports extensions
C. It bypasses the need for pg_hba.conf configuration
D. It offers the latest PostgreSQL major and minor versions faster than most distro repos, which often lag behind

Answer: 

**3.** Which is a valid PostgreSQL connection URI recognized by psql?
A. jdbc:postgres://host/dbname
B. mssql://host:1433/dbname
C. pg://host/dbname?auth=scram
D. postgresql://user:password@host:5432/dbname

Answer: 

**4.** What is the role of the postmaster process?
A. It handles only WAL writing
B. It is spawned fresh for every query
C. It is the parent process that listens for connections, forks a new backend per client, and manages shared server resources and background processes
D. It only exists during initdb

Answer: 

**5.** What is the core difference between a physical backup and a logical backup?
A. A physical backup only backs up roles; a logical backup only backs up table data
B. There is no meaningful difference — both produce identical files
C. A physical backup copies the raw data files/cluster at the storage level; a logical backup exports data as SQL statements or a portable dump format
D. A logical backup requires the server to be offline; a physical backup does not

Answer: 

**6.** What is the core idea behind Multi-Version Concurrency Control (MVCC) in PostgreSQL?
A. Every transaction locks the entire table for the duration of its work
B. Only one transaction may run at a time
C. All updates are applied in-place with no versioning
D. Readers and writers don't block each other because each transaction sees a consistent snapshot of row versions valid at a particular point in time

Answer: 

**7.** Why is VACUUM necessary in PostgreSQL?
A. To reclaim space from dead tuples left by UPDATE/DELETE, update visibility map/free space map info, and prevent transaction ID wraparound issues
B. To physically defragment WAL files
C. It's only needed if you never run ANALYZE
D. To rebuild all indexes from scratch

Answer: 

**8.** What's the difference between pg_cancel_backend() and pg_terminate_backend()?
A. They are functionally identical
B. pg_terminate_backend() only works on the current session
C. pg_cancel_backend() cancels the currently running query but keeps the session/connection open; pg_terminate_backend() forcibly ends the entire backend process/connection
D. pg_cancel_backend() requires superuser, pg_terminate_backend() does not

Answer: 

**9.** Which environment variable typically points to the PostgreSQL data directory, and what does that directory contain?
A. PGHOME; it contains only the binaries
B. PGDATA; it contains the cluster's configuration files, WAL, and table/index data files
C. PGPORT; it specifies the listening port only
D. PGLIB; it contains only shared libraries

Answer: 

**10.** Which CREATE ROLE clause allows a role to actually establish a database connection?
A. NOLOGIN
B. CREATEDB
C. REPLICATION
D. LOGIN

Answer: 

**11.** Which psql meta-command lists all databases on the server?
A. \dt
B. \d
C. \du
D. \l

Answer: 

**12.** What does the pg_blocking_pids(pid) function return?
A. An array of process IDs of the sessions that are blocking the given session's lock request
B. The total number of connections to the database
C. The pid of the postmaster
D. A list of all idle sessions

Answer: 

**13.** What are PostgreSQL background workers used for?
A. Only for replication
B. They replace the postmaster on restart
C. They handle only client authentication
D. General-purpose or extension-driven background tasks (e.g. logical replication workers, custom extension jobs) that run asynchronously from client backends

Answer: 

**14.** What is the primary purpose of a PostgreSQL tablespace?
A. To define a schema's search_path
B. To create a temporary staging area for VACUUM
C. To let you store database objects on a different filesystem location/disk than the default data directory
D. To partition a table automatically by date

Answer: 

**15.** In pg_locks, what does a row with `granted = false` represent?
A. A lock that has been released
B. An error in the locking subsystem
C. A lock request that is still waiting to be granted (i.e., the session is blocked)
D. A lock held by a superuser

Answer: 

**16.** Which statement creates a new database owned by a specific role?
A. CREATE SCHEMA sales OWNER sales_admin;
B. ALTER DATABASE sales SET OWNER = sales_admin;
C. CREATE DATABASE sales OWNER sales_admin;
D. GRANT sales TO sales_admin;

Answer: 

**17.** Which pg_dump format flag produces a compressed, non-plain-text archive that can be selectively restored with pg_restore?
A. -F p (plain)
B. -F c (custom)
C. -F t only supports full restores
D. pg_dump has no format flags

Answer: 

**18.** Why does an UPDATE or DELETE in PostgreSQL leave behind old row versions that eventually require VACUUM?
A. MVCC keeps old tuple versions so concurrent transactions can still see a consistent snapshot; once no transaction needs them, VACUUM reclaims that dead tuple space
B. PostgreSQL never physically removes old rows without an explicit DELETE statement
C. Old versions are automatically deleted at COMMIT time, so VACUUM is unnecessary
D. Row versioning only applies to indexes, not heap tuples

Answer: 

**19.** How does regular VACUUM help prevent transaction ID wraparound problems?
A. It freezes old tuples (marking them as visible to all transactions) so their original transaction IDs no longer need to be tracked as the counter advances
B. It has no relationship to wraparound — only VACUUM FREEZE does
C. It deletes the transaction ID counter and resets it to zero
D. It disables MVCC entirely

Answer: 

**20.** After editing postgresql.conf to change a setting that doesn't require a restart, which command applies the change without dropping connections?
A. pg_ctl restart
B. SELECT pg_reload_conf(); (or pg_ctl reload)
C. DROP DATABASE and recreate it
D. ALTER SYSTEM RESTART

Answer: 

**21.** In pg_stat_database, what do the xact_commit and xact_rollback columns tell you?
A. The number of tables in the database
B. The current number of active connections
C. The total number of transactions that have committed vs. rolled back in that database
D. The size of the database on disk

Answer: 

**22.** How does PostgreSQL typically handle a new client connection?
A. All clients share one single backend process
B. The postmaster forks a dedicated backend process for each connection
C. Backends are created only for write queries, not reads
D. Connections are handled entirely inside the WAL writer process

Answer: 

**23.** If a table `orders` exists in schema `sales` but not in `public`, and your search_path is `"$user", public`, what happens when you run `SELECT * FROM orders;` without qualifying the schema?
A. It automatically finds it in the sales schema
B. It silently returns zero rows
C. It fails with "relation does not exist" unless you qualify it as sales.orders or add sales to search_path
D. PostgreSQL searches every schema in the database automatically

Answer: 

**24.** What does pg_hba.conf control?
A. The location of the data directory
B. The size of shared_buffers
C. WAL archiving destinations
D. Which client connections are permitted, and by which authentication method, based on address/database/user

Answer: 

**25.** Which function returns the on-disk size of a single table, in bytes?
A. pg_database_size()
B. pg_relation_size() only works on databases
C. pg_stat_user_tables()
D. pg_table_size()

Answer: 

**26.** What does the INHERIT attribute (the default) on a role control?
A. Whether the role automatically has the privileges of roles it is a member of, without needing SET ROLE
B. Whether the role can create new roles
C. Whether the role's password expires
D. Whether the role can bypass row-level security

Answer: 

**27.** What does pg_dumpall capture that a per-database pg_dump does not?
A. Table row data only
B. WAL files
C. Index definitions only
D. Cluster-wide objects like roles and tablespaces, across all databases

Answer: 

**28.** Which PostgreSQL transaction isolation level prevents non-repeatable reads by using a snapshot taken at the start of the transaction (not each statement)?
A. READ COMMITTED
B. READ UNCOMMITTED
C. AUTOCOMMIT
D. REPEATABLE READ

Answer: 

**29.** Which of these correctly distinguishes VACUUM FULL from plain VACUUM?
A. They are functionally identical
B. VACUUM FULL rewrites the entire table into a new file to reclaim space back to the OS (requiring an exclusive lock), while plain VACUUM reclaims space for reuse within the table without a full rewrite or exclusive lock
C. VACUUM FULL only updates planner statistics
D. VACUUM FULL is deprecated and no longer available

Answer: 

**30.** In pg_stat_all_tables (or pg_stat_user_tables), a table showing a high seq_scan count and near-zero idx_scan count most likely suggests:
A. The table is perfectly indexed and optimized
B. Queries against that table are doing sequential scans rather than using an index — possibly a missing or unused index
C. The table has been vacuumed too often
D. Autovacuum is disabled on that table

Answer: 

**31.** Which pg_hba.conf authentication method is the current recommended default for password-based authentication in PostgreSQL 18?
A. scram-sha-256
B. md5
C. trust
D. password

Answer: 

**32.** Which clause enforces that a column's value must be unique and not null, typically used for a table's primary key?
A. DEFAULT
B. CHECK
C. UNLOGGED
D. PRIMARY KEY

Answer: 

**33.** What is the role of shared_buffers?
A. It's a per-session buffer for sorting only
B. It's PostgreSQL's main shared memory cache for table and index data pages, reducing disk I/O
C. It stores compiled query plans
D. It is only used during VACUUM

Answer: 

**34.** How can pg_stat_all_indexes (or pg_stat_user_indexes) help you find unused indexes?
A. It cannot — index usage isn't tracked
B. It only tracks primary key indexes
C. A very low or zero idx_scan count for an index over time suggests it's rarely or never used and may be a candidate for removal
D. It reports index bloat percentage directly

Answer: 

**35.** Which postgresql.conf parameters point to the server's SSL certificate and private key for encrypting client connections?
A. ssl_cert_file and ssl_key_file
B. archive_command and archive_mode
C. log_destination and log_directory
D. wal_level and wal_sync_method

Answer: 

**36.** Which PostgreSQL data type is best suited for storing semi-structured data with indexing support for containment queries?
A. jsonb
B. text
C. bytea
D. xml

Answer: 

**37.** What kind of information does pg_stat_bgwriter historically provide?
A. Row-level lock statistics
B. Query text of slow queries
C. Counts related to buffers written by the background writer/backends and checkpoint-related I/O statistics
D. Replication lag in seconds

Answer: 

**38.** When a role creates a table, who owns it by default, and what privilege does that confer?
A. The creating role owns it, and owners implicitly have all privileges on the object (can grant, alter, drop it)
B. The public role owns it, granting all users full access
C. No one owns it until explicitly assigned with ALTER TABLE OWNER TO
D. The superuser always becomes the owner regardless of who ran CREATE TABLE

Answer: 

**39.** Which tool is used to restore a custom-format (-F c) pg_dump archive?
A. pg_restore
B. psql
C. pg_basebackup
D. pg_upgrade

Answer: 

**40.** Which pg_ctl subcommand stops and then starts the PostgreSQL server in one step?
A. pg_ctl reload
B. pg_ctl restart
C. pg_ctl status
D. pg_ctl promote

Answer: 

**41.** What's the difference between work_mem and maintenance_work_mem?
A. They are identical settings under different names
B. maintenance_work_mem controls shared_buffers sizing
C. work_mem bounds memory for operations like sorts/hash joins per query operation; maintenance_work_mem bounds memory for maintenance operations like VACUUM, CREATE INDEX, and ALTER TABLE
D. work_mem only applies to autovacuum

Answer: 

**42.** Which of these is an example of a row-level lock rather than a table-level lock?
A. The lock acquired by SELECT ... FOR UPDATE on the rows it selects
B. ACCESS EXCLUSIVE from ALTER TABLE
C. LOCK TABLE ... IN ACCESS SHARE MODE
D. A lock taken during CREATE INDEX (non-concurrent)

Answer: 

**43.** At a high level, how does the autovacuum daemon decide when to vacuum a table?
A. It vacuums every table on a fixed nightly schedule regardless of activity
B. The autovacuum launcher periodically wakes (per autovacuum_naptime) and triggers workers on tables whose dead tuple count exceeds a threshold based on autovacuum_vacuum_threshold and autovacuum_vacuum_scale_factor
C. It only runs when a superuser manually triggers it
D. It vacuums only system catalogs, never user tables

Answer: 

**44.** Since PostgreSQL 17, checkpoint-related statistics that used to live in pg_stat_bgwriter were moved to which dedicated view?
A. pg_stat_io
B. pg_stat_checkpointer
C. pg_stat_wal
D. pg_stat_database_conflicts

Answer: 

**45.** A SQL Server developer new to PostgreSQL writes `SELECT first_name + ' ' + last_name FROM employees;` and gets a type error. What's the correct PostgreSQL equivalent?
A. SELECT first_name || ' ' || last_name FROM employees;
B. SELECT first_name . ' ' . last_name FROM employees;
C. SELECT CONCAT_WS(first_name, ' ', last_name) FROM employees;
D. SELECT first_name & ' ' & last_name FROM employees;

Answer: 

**46.** On a systemd-based Linux distribution, which command would you use to enable PostgreSQL to start automatically at boot?
A. pg_ctl enable postgresql
B. systemctl enable postgresql
C. initdb --autostart
D. postgres --enable-boot

Answer: 

**47.** What must you do to enable pg_stat_statements for tracking query performance?
A. Nothing — it's on by default in every PostgreSQL installation
B. Set track_activities = on only
C. Add pg_stat_statements to shared_preload_libraries (and restart), then run CREATE EXTENSION pg_stat_statements;
D. It can only be enabled via a third-party monitoring agent

Answer: 

**48.** Which process is responsible for periodically flushing all dirty shared buffers to disk at a checkpoint, as opposed to the background writer's incremental flushing between checkpoints?
A. The autovacuum launcher
B. The WAL sender
C. The checkpointer
D. The stats collector

Answer: 

**49.** When you run `CREATE INDEX idx_name ON mytable (col);` without specifying a method, which index type is created by default?
A. hash
B. gin
C. btree
D. brin

Answer: 

**50.** What does the pg_isready utility check?
A. Whether the PostgreSQL server is accepting connections
B. Whether a specific table has bloat
C. Whether WAL archiving is up to date
D. Whether autovacuum is currently running

Answer: 

**51.** In pg_stat_statements, which column tells you the average execution time per call for a normalized query?
A. mean_exec_time
B. calls
C. total_exec_time
D. rows

Answer: 

**52.** What does pg_basebackup produce?
A. A logical SQL dump of table contents
B. A schema-only export
C. A compressed export of just the WAL archive
D. A physical, file-level copy of the entire data directory, suitable as a base for PITR or a replica

Answer: 

**53.** Which system view would you query to see currently held and waiting locks, including which are blocking which?
A. pg_stat_activity only
B. pg_stat_database
C. pg_locks
D. pg_settings

Answer: 

**54.** What does autovacuum_vacuum_scale_factor represent?
A. A fixed number of dead rows that triggers a vacuum, ignoring table size
B. A fraction of the table's total row count (added to autovacuum_vacuum_threshold) that determines how many dead tuples trigger an autovacuum run
C. The percentage of CPU autovacuum is allowed to use
D. The number of autovacuum worker processes allowed cluster-wide

Answer: 

**55.** Which statement grants SELECT and INSERT privileges on a table to a role?
A. ALLOW SELECT, INSERT ON mytable TO myrole;
B. GRANT myrole SELECT, INSERT ON mytable;
C. SET PRIVILEGES SELECT, INSERT ON mytable FOR myrole;
D. GRANT SELECT, INSERT ON mytable TO myrole;

Answer: 

**56.** Which of these is a valid value for log_destination?
A. binarylog
B. xmllog
C. netlog
D. jsonlog

Answer: 

**57.** What is PostgreSQL's typical major release cadence and support window?
A. A new major version every 5 years, supported indefinitely
B. A new major version every month
C. A new major version roughly every year, with each version supported for about 5 years
D. Major versions are retired after 6 months

Answer: 

**58.** What is the key functional difference between a regular VIEW and a MATERIALIZED VIEW?
A. A materialized view updates automatically in real time; a regular view does not
B. There is no functional difference, only naming
C. A regular view always reflects live underlying data on every query; a materialized view stores a snapshot that must be refreshed with REFRESH MATERIALIZED VIEW to update
D. A regular view can be indexed; a materialized view cannot

Answer: 

**59.** Why does PostgreSQL use Write-Ahead Logging (WAL)?
A. To ensure durability and crash recovery by recording changes before they're applied to data files, so committed transactions survive a crash
B. To speed up SELECT queries only
C. To replace the need for shared_buffers
D. It's used exclusively for logical replication and has no other purpose

Answer: 

**60.** Which log_min_messages value would show more detail: DEBUG1 or WARNING?
A. WARNING shows strictly more detail than DEBUG1
B. DEBUG1 shows more detail (lower severity threshold) than WARNING, which only logs warnings and more severe messages
C. They log identical amounts of detail
D. log_min_messages has no effect on verbosity

Answer: 

**61.** What is required to apply a PostgreSQL minor version update (e.g. 18.1 to 18.2)?
A. A full pg_dump and restore into a new cluster
B. Installing the new minor version binaries and restarting the server — no dump/restore or pg_upgrade needed
C. Running pg_upgrade in link mode
D. Rebuilding all indexes manually

Answer: 

**62.** To enable continuous WAL archiving, which two settings must typically be configured together?
A. archive_mode = on and a working archive_command
B. shared_buffers and work_mem
C. log_statement and log_duration
D. autovacuum and vacuum_cost_delay

Answer: 

**63.** What does the deadlock_timeout parameter control?
A. How long a transaction can run before being auto-committed
B. How long a backend waits for a lock before PostgreSQL checks for a deadlock condition
C. The maximum lifetime of a WAL segment
D. How often autovacuum checks for bloat

Answer: 

**64.** Which function both advances a sequence and returns its new value?
A. nextval()
B. currval()
C. setval()
D. lastval() without prior nextval in session

Answer: 

**65.** What does the `VACUUM (SKIP_LOCKED)` option do?
A. It skips relations that cannot be locked immediately (e.g. already locked by another process), rather than waiting, allowing the vacuum run to continue with other tables
B. It is not a valid VACUUM option
C. It permanently skips vacuuming any row that has ever been locked
D. It disables all locking for the duration of the VACUUM

Answer: 

**66.** What does setting log_error_verbosity = verbose add to log entries compared to default?
A. Nothing different from terse
B. It adds the source code file name, function name, and line number that generated the log message, in addition to the default detail
C. It suppresses all but error-level messages
D. It switches the log format to JSON

Answer: 

**67.** Which of these is NOT one of the standard methods for performing a major version upgrade of PostgreSQL?
A. pg_upgrade
B. Dump and restore (pg_dump/pg_dumpall + restore)
C. Logical replication to a new-version cluster, then switchover
D. In-place minor patching via apt/yum update alone

Answer: 

**68.** What is the role of the WAL writer process?
A. It writes table data pages to disk
B. It only runs during a base backup
C. It handles client authentication over SSL
D. It periodically flushes WAL data from wal_buffers (in-memory) to disk, even between transaction commits

Answer: 

**69.** What does setting log_min_duration_statement = 1000 do?
A. Logs every statement, regardless of duration
B. Prevents any statement from running longer than 1 second
C. Logs only statements that take 1000 milliseconds (1 second) or longer to execute
D. Sets the connection timeout to 1000ms

Answer: 

**70.** What is a key difference between a PostgreSQL FUNCTION and a PROCEDURE?
A. Only a PROCEDURE can be invoked with CALL and can manage its own transactions (COMMIT/ROLLBACK inside it); a FUNCTION is invoked with SELECT and cannot control transactions
B. FUNCTIONs cannot return values
C. PROCEDUREs cannot take parameters
D. They are identical in every respect

Answer: 

**71.** Since PostgreSQL 15, what changed about the default privileges on the `public` schema for newly created databases?
A. Nothing changed; PUBLIC has always had CREATE on the public schema
B. The public schema was removed entirely
C. The PUBLIC role no longer has CREATE privilege on the public schema by default — only the database owner does, unless explicitly granted
D. All roles now automatically get superuser rights in the public schema

Answer: 

**72.** What does pg_upgrade's link mode (--link) do differently from its default copy mode?
A. It copies all data files to the new cluster, doubling disk usage temporarily
B. It performs the upgrade entirely over network replication
C. It skips upgrading system catalogs
D. It hard-links data files between old and new clusters instead of copying them, making the upgrade much faster but preventing the old cluster from being used independently afterward

Answer: 

**73.** What do log_rotation_age and log_rotation_size control together?
A. How long autovacuum waits between runs
B. When the logging collector starts a new log file — either after a time interval or once the current file reaches a size threshold
C. How long WAL segments are retained
D. The maximum number of concurrent connections logged

Answer: 

**74.** At a conceptual level, what does Point-in-Time Recovery (PITR) let you do?
A. Instantly roll back a single transaction without touching the rest of the database
B. Restore a base backup and then replay archived WAL up to a specific target time/LSN/transaction, rather than only to the moment the backup was taken
C. Recover deleted rows from the buffer cache without any backup
D. Skip WAL replay entirely for faster restores

Answer: 

**75.** Under the default READ COMMITTED isolation level, when does a transaction acquire a new MVCC snapshot?
A. Once, at BEGIN, for the life of the transaction
B. At the start of each individual statement, so later statements can see rows committed by other transactions in the meantime
C. Only at COMMIT
D. It never takes a snapshot — it always reads current heap state directly

Answer: 

**76.** How can you override autovacuum's scale factor for one specific high-churn table without changing the cluster-wide default in postgresql.conf?
A. ALTER TABLE mytable SET (autovacuum_vacuum_scale_factor = 0.01);
B. It cannot be done per table — it's a global setting only
C. SET autovacuum_vacuum_scale_factor = 0.01; in your session before running queries
D. Rename the table to trigger a config reload

Answer: 

**77.** In PostgreSQL 18, when `io_method = worker` is configured, what `backend_type` value would you expect to see in `pg_stat_activity` for the processes handling asynchronous I/O?
A. client backend
B. checkpointer
C. autovacuum launcher
D. IO Worker

Answer: 

**78.** In PostgreSQL, what is the difference between LIKE and ILIKE, and how do single vs. double quotes differ?
A. LIKE is case-insensitive and ILIKE is case-sensitive; quotes are interchangeable
B. LIKE and ILIKE are identical; double quotes delimit strings
C. ILIKE only works on numeric columns
D. ILIKE is a case-insensitive pattern match (LIKE is case-sensitive); single quotes delimit string literals while double quotes delimit identifiers

Answer: 

**79.** What is the default TCP port PostgreSQL listens on?
A. 1433
B. 3306
C. 8080
D. 5432

Answer: 

**80.** Setting log_statement = 'ddl' will log which kinds of statements?
A. Only SELECT statements
B. Every single statement executed, including SELECTs
C. Data definition statements like CREATE, ALTER, DROP (but not ordinary DML like INSERT/UPDATE)
D. Nothing — 'ddl' is not a valid value

Answer: 

---

*When finished, let Claude know — grading and a per-topic score log will follow.*
